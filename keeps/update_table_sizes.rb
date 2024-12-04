# frozen_string_literal: true

require_relative 'helpers/reviewer_roulette'

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

    def each_change
      return unless tables_to_update.any?

      change = build_change(tables_to_update.keys)
      change.changed_files = []

      tables_to_update.each do |table_name, classification|
        change.changed_files << update_dictionary_file(table_name, classification)
      end

      yield(change)
    end

    private

    def table_sizes
      table_sizes = {}

      database_entries.each do |entry|
        connection = Gitlab::Database.schemas_to_base_models[entry.gitlab_schema]&.first&.connection
        next unless connection

        with_shared_connection(connection) do
          table_size = Gitlab::Database::PostgresTableSize.by_table_name(entry.table_name)
          next unless table_size

          table_sizes[table_size.table_name] = table_size.size_classification
        end
      end

      table_sizes
    end
    strong_memoize_attr :table_sizes

    def database_entries
      @database_entries ||= Gitlab::Database::Dictionary.entries
    end

    def tables_to_update
      tables_to_update = {}

      database_entries.each do |entry|
        next unless entry.table_size != table_sizes[entry.table_name]
        next if table_sizes[entry.table_name].nil?

        tables_to_update[entry.table_name] = table_sizes[entry.table_name]
      end

      tables_to_update
    end
    strong_memoize_attr :tables_to_update

    def build_change(table_names)
      change = ::Gitlab::Housekeeper::Change.new
      change.title = "Update table_size database dictionary entries".truncate(70, omission: '')
      change.identifiers = change_identifiers
      change.changelog_type = 'added'
      change.labels = labels
      change.reviewers = reviewer('maintainer::database')

      change.description = <<~MARKDOWN
      Updates database dictionary entries for `#{table_names.join(', ')}`

      You can read more about our process to classify table size in
      https://docs.gitlab.com/ee/development/database/large_tables_limitations.html.

      Verify this MR as it was automatically created by `gitlab-housekeeper`.
      MARKDOWN

      change
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

    def labels
      [
        'database',
        'backend',
        'group::database',
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

    def with_shared_connection(connection, &block)
      Gitlab::Database::SharedModel.using_connection(connection, &block)
    end

    def reviewer(role)
      roulette.random_reviewer_for(role)
    end

    def roulette
      @roulette ||= Keeps::Helpers::ReviewerRoulette.new
    end
  end
end
