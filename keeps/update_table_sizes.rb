# frozen_string_literal: true

require_relative 'helpers/reviewer_roulette'
require_relative './helpers/postgres_ai'

module Keeps
  # This is an implementation of ::Gitlab::Housekeeper::Keep.
  # This updates table_size dictionary entries of gitlab databases.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::UpdateTableSizes
  # ```
  class UpdateTableSizes < ::Gitlab::Housekeeper::Keep
    include Gitlab::Utils::StrongMemoize

    RUBOCOP_PATH = 'rubocop/rubocop-migrations.yml'

    def each_identified_change
      return unless tables_to_update.any?

      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = change_identifiers
      change.context = {
        tables_to_update: tables_to_update,
        partitioned_tables: partitioned_tables_to_update
      }
      yield(change)
    end

    def make_change!(change)
      tables_to_update = change.context[:tables_to_update]
      partitioned_tables = change.context.fetch(:partitioned_tables, {})
      build_change_details(change, tables_to_update.keys, partitioned_tables)
      change.changed_files = []

      tables_to_update.each do |table_name, classification|
        change.changed_files << update_dictionary_file(table_name, classification)
      end

      update_rubocop_migrations_file(tables_to_update)
      change.changed_files << RUBOCOP_PATH

      change
    end

    private

    # Maps each dictionary table to the relation that classifies it:
    #
    #   { classification: 'medium', measured_relation: 'gitlab_partitions_static.foo_12',
    #     size_in_bytes: 45_097_156_608, partitioned: true }
    #
    # For an unpartitioned table the measured relation is the table itself. For a partitioned
    # table it is the largest partition, as the database dictionary defines the size of a
    # partitioned table to be the size of its largest partition.
    def table_sizes
      table_sizes = {}

      database_entries.each do |entry|
        connection = Gitlab::Database.schemas_to_base_models[entry.gitlab_schema]&.first&.connection
        next unless connection
        # Write-locked tables belong to another database, where they may well be non-empty, so
        # classifying them from here would wrongly demote them (see
        # https://gitlab.com/gitlab-org/gitlab/-/issues/526457). Genuinely empty tables (for
        # example, truncated ones) carry no lock trigger and are still reclassified.
        next if table_write_locked?(entry.table_name)

        table_size = fetch_table_size(entry.table_name)
        next unless table_size

        table_sizes[entry.table_name] = table_size
      end

      table_sizes
    end
    strong_memoize_attr :table_sizes

    def table_write_locked?(table_name)
      postgres_ai.table_write_locked?(table_name)
    end

    def fetch_table_size(table_name)
      row = postgres_ai.fetch_postgres_table_size(table_name).first
      return unless row

      {
        classification: row.fetch('classification'),
        measured_relation: row.fetch('identifier'),
        size_in_bytes: row.fetch('size_in_bytes').to_i,
        partitioned: Gitlab::Utils.to_boolean(row.fetch('is_partition'))
      }
    end

    def database_entries
      @database_entries ||= Gitlab::Database::Dictionary.entries
    end

    def tables_to_update
      tables_to_update = {}

      database_entries.each do |entry|
        table_size = table_sizes[entry.table_name]

        next if table_size.nil?
        next if entry.table_size == table_size[:classification]
        next if entry.gitlab_schema == 'gitlab_internal'

        tables_to_update[entry.table_name] = table_size[:classification]
      end

      tables_to_update
    end
    strong_memoize_attr :tables_to_update

    # The subset of tables_to_update whose classification came from a partition, mapped to that
    # partition and its size. Surfaced in the merge request so the blast radius of reclassifying
    # partitioned tables is visible to the reviewer.
    def partitioned_tables_to_update
      tables_to_update.keys.filter_map do |table_name|
        table_size = table_sizes[table_name]
        next unless table_size[:partitioned]

        [table_name, { relation: table_size[:measured_relation], size_in_bytes: table_size[:size_in_bytes] }]
      end.to_h
    end

    def build_change_details(change, table_names, partitioned_tables)
      change.title = "Update table_size database dictionary entries".truncate(70, omission: '')
      change.changelog_type = 'added'
      change.labels = labels
      change.reviewers = reviewer('maintainer::database')

      change.description = <<~MARKDOWN
      Updates database dictionary entries for `#{table_names.join(', ')}`.

      The classification of table size changed as defined in the [database dictionary](https://docs.gitlab.com/development/database/database_dictionary/#schema).

      Read more about our process to classify table size in our [documentation](https://docs.gitlab.com/ee/development/database/large_tables_limitations.html).

      Verify this MR by inspecting the `postgres_table_sizes` view for each affected table.
      MARKDOWN

      change.description += partitioned_tables_section(partitioned_tables) if partitioned_tables.any?
    end

    def partitioned_tables_section(partitioned_tables)
      rows = partitioned_tables.map do |table_name, partition|
        size = ActiveSupport::NumberHelper.number_to_human_size(partition[:size_in_bytes])

        "| `#{table_name}` | `#{partition[:relation]}` | #{size} |"
      end

      <<~MARKDOWN

      ## Partitioned tables

      The following tables are partitioned. As defined in the database dictionary, each is classified by the size of its largest partition, listed below. Verify these by inspecting the `postgres_table_sizes` row of the partition rather than the parent table, which holds no data.

      | Table | Largest partition | Size |
      | ----- | ----------------- | ---- |
      #{rows.join("\n")}
      MARKDOWN
    end

    def update_dictionary_file(table_name, size)
      dictionary_path = File.join('db', 'docs', "#{table_name}.yml")
      dictionary = begin
        YAML.safe_load_file(dictionary_path)
      rescue StandardError
        {}
      end

      dictionary['table_size'] = size
      File.write(dictionary_path, dictionary.to_yaml)

      dictionary_path
    end

    def update_rubocop_migrations_file(table_names)
      yaml_content = load_rubocop_migrations_config

      update_tables_in_config(yaml_content, group_tables_by_classification(table_names))

      File.write(RUBOCOP_PATH, yaml_content.to_yaml)
    end

    def load_rubocop_migrations_config
      @rubocop_migrations_config ||= YAML.load_file(RUBOCOP_PATH)
    end

    def group_tables_by_classification(table_names)
      table_names.group_by { |_k, v| v }.transform_values { |v| v.map(&:first) }
    end

    def update_tables_in_config(config, tables_by_classification)
      large_tables = config['Migration/UpdateLargeTable'].slice('LargeTables', 'OverLimitTables').values.flatten.uniq

      tables_by_classification.each do |size, new_tables|
        rubocop_classification = rubocop_size_classification(size)
        demoted_tables = large_tables & new_tables.map(&:to_sym)

        # At this point, we know if the table was promoted to "large" or "over limit", but we don't know if the table
        # was demoted to "small" or "medium". If that's the case, we must remove the table from rubocop-migrations.yml.
        remove_tables(demoted_tables, config) if !rubocop_classification && demoted_tables.any?

        next unless rubocop_classification

        existing_tables = config.dig('Migration/UpdateLargeTable', rubocop_classification) || []
        updated_tables = merge_and_sort_tables(existing_tables, new_tables)

        config['Migration/UpdateLargeTable'][rubocop_classification] = updated_tables
      end
    end

    def remove_tables(tables, config)
      tables.each do |table_to_remove|
        config['Migration/UpdateLargeTable']['LargeTables'].delete(table_to_remove)
        config['Migration/UpdateLargeTable']['OverLimitTables'].delete(table_to_remove)
      end
    end

    def merge_and_sort_tables(existing_tables, new_tables)
      (existing_tables + new_tables.map(&:to_sym)).uniq.sort
    end

    def rubocop_size_classification(size)
      case size
      when 'large'
        'LargeTables'
      when 'over_limit'
        'OverLimitTables'
      end
    end

    def labels
      [
        'database',
        'backend',
        'group::database frameworks',
        'devops::data stores',
        'section::core platform',
        'maintenance::workflow',
        'type::maintenance',
        'database::review pending',
        'workflow::in review'
      ]
    end

    def change_identifiers
      [self.class.name.demodulize, Date.current.iso8601, SecureRandom.alphanumeric]
    end

    def reviewer(role)
      roulette.random_reviewer_for(role)
    end

    def roulette
      Keeps::Helpers::ReviewerRoulette.instance
    end

    def postgres_ai
      @postgres_ai ||= Keeps::Helpers::PostgresAi.new
    end
  end
end
