# frozen_string_literal: true

require 'cgi'
require_relative 'helpers/groups'
require_relative 'helpers/grafana_unused_index_query'
require_relative 'helpers/index_keep_list'
require_relative '../lib/generators/post_deployment_migration/post_deployment_migration_generator'

module Keeps
  # For each PostgreSQL index with no activity on GitLab.com, generates a
  # post-deploy migration that removes it synchronously with
  # `remove_concurrent_index_by_name` and yields a Change so the runner opens a
  # merge request. For large tables the reviewer should switch to asynchronous
  # removal instead, per `doc/development/database/adding_database_indexes.md`.
  #
  # Requires `GITLAB_GRAFANA_API_URL`, `GITLAB_GRAFANA_API_KEY`,
  # `GITLAB_GRAFANA_DATASOURCE_UID`. Optional `GITLAB_GRAFANA_ENV` selects the
  # `env=` PromQL label (defaults to `gprd`; set to `gstg` for staging tests).
  #
  # Resets the test database on each run. Invoke standalone with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::CleanupUnusedIndexes
  # ```
  class CleanupUnusedIndexes < ::Gitlab::Housekeeper::Keep
    MIGRATION_TEMPLATE = 'generator_templates/active_record/migration/'
    FALLBACK_REVIEWER_FEATURE_CATEGORY = 'database'

    # Sourced from the helper so the rendered description can't drift from
    # the actual query window.
    MIMIR_LOOKBACK_DAYS = Keeps::Helpers::GrafanaUnusedIndexQuery::LOOKBACK_DAYS
    private_constant :MIMIR_LOOKBACK_DAYS

    # Restrict to the public schema so it lines up with ForeignKeyIndexes::INDEX_SCHEMA
    # and explicitly excludes the gitlab_partitions_* schemas exposed by the view.
    INDEX_SCHEMA = 'public'
    private_constant :INDEX_SCHEMA

    # Heavy-write tables make unused indexes cost the most (write amplification,
    # LWLock contention), so they surface first. Source: `table_size` in db/docs.
    TABLE_SIZE_WEIGHT = {
      'over_limit' => 4,
      'large' => 3,
      'medium' => 2,
      'small' => 1,
      'unknown' => 0
    }.freeze
    private_constant :TABLE_SIZE_WEIGHT

    def each_identified_change
      unless grafana_query.available?
        raise "Grafana credentials missing; cannot detect unused indexes. " \
          "Set #{Keeps::Helpers::GrafanaUnusedIndexQuery::API_URL_ENV}, " \
          "#{Keeps::Helpers::GrafanaUnusedIndexQuery::API_KEY_ENV}, " \
          "#{Keeps::Helpers::GrafanaUnusedIndexQuery::DATASOURCE_UID_ENV}."
      end

      ensure_test_db!

      candidate_indexes.each do |index|
        change = build_change_for(index)
        yield(change) if change
      rescue StandardError => e
        @logger.puts "[CleanupUnusedIndexes] Skipping #{index.identifier}: #{e.class}: #{e.message}"
        next
      end
    end

    def make_change!(change)
      ctx = change.context
      ensure_test_db!

      built = migration_builder.build(ctx)

      change.changed_files = [
        built.migration_file,
        built.digest_file
      ]

      # The synchronous removal alters the schema, so apply it to regenerate
      # db/structure.sql, then restore the test DB for the next change.
      migrate
      change.changed_files << Pathname.new('db').join('structure.sql').to_s
      reset_db

      build_change_details(change, ctx)
      change
    end

    private

    def ensure_test_db!
      return if @test_db_ready

      ::Gitlab::Application.load_tasks
      ::PostDeploymentMigration::PostDeploymentMigrationGenerator.source_root(MIGRATION_TEMPLATE)

      reset_db
      migrate

      @test_db_ready = true
    end

    def build_change_for(index)
      return unless matches_filter_identifiers?([self.class.name.demodulize, index.schema, index.name])
      return if keep_list.exempt?(index.schema, index.name)
      return if foreign_key_indexes.include?(index.identifier)

      entry = dictionary_entry(index.tablename)
      gitlab_schema = entry&.gitlab_schema
      return if gitlab_schema.blank?

      cluster_type = cluster_mapper.for_schema(gitlab_schema)
      return unless grafana_query.unused?(
        table: index.tablename,
        type: cluster_type,
        indexrelname: index.name
      ) == true

      columns = columns_for(index)
      return if columns.empty?

      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = [self.class.name.demodulize, index.schema, index.name]
      change.context = {
        schema: index.schema,
        name: index.name,
        tablename: index.tablename,
        gitlab_schema: gitlab_schema,
        cluster_type: cluster_type,
        definition: index.definition,
        columns: columns
      }
      change
    end

    # rubocop:disable CodeReuse/ActiveRecord -- The Keep operates against the test DB only.
    # `unique: false` already excludes primary-key indexes (PKs are always unique).
    def candidate_indexes
      @candidate_indexes ||= Gitlab::Database::SharedModel.using_connection(test_db_connection) do
        Gitlab::Database::PostgresIndex
          .where(schema: INDEX_SCHEMA, unique: false, exclusion: false,
            expression: false, partial: false, valid_index: true)
          .not_match("#{Gitlab::Database::Reindexing::ReindexConcurrently::TEMPORARY_INDEX_PATTERN}$")
          .without_parent_partitioned_tables
          .to_a
          .sort_by { |index| priority_key_for(index) }
      end
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # Trailing index.name keeps ordering stable across runs when multiple
    # indexes share the same table_size weight.
    def priority_key_for(index)
      entry = dictionary_entry(index.tablename)
      size_weight = TABLE_SIZE_WEIGHT.fetch(entry&.table_size || 'unknown', 0)

      [-size_weight, index.name]
    end

    def columns_for(index)
      index_def = indexes_for_table(index.tablename).find { |i| i.name == index.name }
      Array(index_def&.columns).map(&:to_sym)
    end

    def indexes_for_table(tablename)
      @indexes_for_table ||= {}
      @indexes_for_table[tablename] ||= test_db_connection.indexes(tablename)
    end

    def build_change_details(change, ctx)
      change.title = "Remove unused index #{ctx[:name]}".truncate(72)
      change.changelog_type = 'other'
      change.labels = labels(ctx[:tablename])
      change.reviewers = Array(pick_reviewer(ctx[:tablename], change.identifiers))
      change.description = description_for(ctx)
    end

    def description_for(ctx)
      <<~MARKDOWN.chomp
        ## What does this MR do and why?

        Remove the unused index `#{ctx[:schema]}.#{ctx[:name]}` on `#{ctx[:tablename]}`
        with `remove_concurrent_index_by_name`. The index reported **zero scans**
        over a #{MIMIR_LOOKBACK_DAYS}-day pre-filter window on the
        `#{ctx[:cluster_type]}` Patroni cluster. Verify the 180-day chart below as
        confirmation before merging.

        Definition:

        ~~~sql
        #{ctx[:definition]}
        ~~~

        ## :warning: Large tables: remove asynchronously instead

        This MR drops the index **synchronously**, which is fine for small and
        medium tables. On a **large** table a synchronous removal can run for a
        long time, block the deployment, and starve `autovacuum`. If
        `#{ctx[:tablename]}` is a large table, do not merge this as-is: switch to
        asynchronous removal (`prepare_async_index_removal` + a synchronous
        follow-up) per
        [Drop indexes asynchronously](https://docs.gitlab.com/development/database/adding_database_indexes/#drop-indexes-asynchronously).

        ## Required: verify the 180-day Grafana chart before merging

        The Keep's #{MIMIR_LOOKBACK_DAYS}-day window is a fast pre-filter, not
        a final verdict. Per
        [Dropping unused indexes](https://docs.gitlab.com/development/database/adding_database_indexes/#dropping-unused-indexes),
        confirm via Grafana over **at least 6 months** before merging.

        [**Open this query in Grafana Explore**](#{grafana_explore_url_for(ctx)}) (6-month range, #{grafana_datasource_uid}).
        The chart should be flat at `0`. PromQL for reference:

        ```promql
        sum by (indexrelname) (
          increase(pg_stat_user_indexes_idx_scan{
            env="#{grafana_query_env}", type="#{ctx[:cluster_type]}",
            relname="#{ctx[:tablename]}", indexrelname="#{ctx[:name]}"
          }[180d])
        )
        ```

        ## Cross-environment review checklist

        An index that is idle on GitLab.com may still be required elsewhere:

        - [ ] No GitLab Self-Managed or GitLab Dedicated feature relies on this index.
        - [ ] No low-frequency (quarterly, yearly) cron uses the column(s) this index covers.
        - [ ] Kibana (`pubsub-postgres-inf-gprd*`, last 7 days): review `json.sql: #{ctx[:tablename]} AND json.sql: *#{ctx[:columns].first}*` and confirm no query filters/orders on `#{ctx[:columns].map(&:to_s).join(', ')}` in a way this index would serve. A text match alone is not index usage; PostgreSQL favours the index when a query filters on its leading column(s).

        ## If this index must be kept

        Add an entry to `keeps/cleanup_unused_indexes/index_keep_list.yml` and close this MR:

        ```yaml
        "#{ctx[:schema]}.#{ctx[:name]}":
          reason: "<why this index must stay>"
          added_by: "@<your-handle>"
          added_on: "#{Date.current.iso8601}"
        ```

        The Keep will not propose this index again.
      MARKDOWN
    end

    def grafana_explore_url_for(ctx)
      panes = {
        a: {
          datasource: grafana_datasource_uid,
          queries: [{
            datasource: { type: 'prometheus', uid: grafana_datasource_uid },
            editorMode: 'code',
            expr: <<~PROMQL.squish,
              sum by (indexrelname) (
                increase(pg_stat_user_indexes_idx_scan{
                  env="#{grafana_query_env}", type="#{ctx[:cluster_type]}",
                  relname="#{ctx[:tablename]}", indexrelname="#{ctx[:name]}"
                }[180d])
              )
            PROMQL
            refId: 'A'
          }],
          range: { from: 'now-6M', to: 'now' }
        }
      }
      "#{grafana_api_url}/explore?schemaVersion=1&orgId=1&panes=#{CGI.escape(panes.to_json)}"
    end

    def grafana_api_url
      @grafana_api_url ||= ENV.fetch(Keeps::Helpers::GrafanaUnusedIndexQuery::API_URL_ENV, 'https://dashboards.gitlab.net')
    end

    def grafana_datasource_uid
      @grafana_datasource_uid ||= ENV.fetch(
        Keeps::Helpers::GrafanaUnusedIndexQuery::DATASOURCE_UID_ENV,
        'mimir-gitlab-gprd'
      )
    end

    def grafana_query_env
      @grafana_query_env ||= ENV.fetch(
        Keeps::Helpers::GrafanaUnusedIndexQuery::QUERY_ENV_ENV,
        Keeps::Helpers::GrafanaUnusedIndexQuery::DEFAULT_QUERY_ENV
      )
    end

    # Pick one reviewer (from the primary feature category) but label across all.
    def pick_reviewer(table_name, identifiers)
      feature_category = dictionary_feature_categories(table_name).first

      groups_helper.pick_reviewer_for_feature_category(
        feature_category, identifiers,
        fallback_feature_category: FALLBACK_REVIEWER_FEATURE_CATEGORY
      )
    end

    def labels(table_name)
      group_labels = dictionary_feature_categories(table_name).flat_map do |feature_category|
        groups_helper.labels_for_feature_category(feature_category)
      end.uniq

      group_labels + [
        # Dedicated label so every MR from this keep is collectible in one query.
        'automation:cleanup-unused-indexes',
        'maintenance::removal',
        'type::maintenance',
        'Category:Database',
        'pipeline::tier-1',
        'database::review pending',
        'workflow::in review'
      ]
    end

    def dictionary_feature_categories(table_name)
      Array(dictionary_entry(table_name)&.feature_categories)
    end

    # find_by_table_name does a linear scan over ~1500 entries; memoise per table.
    def dictionary_entry(table_name)
      @dictionary_entries ||= {}
      return @dictionary_entries[table_name] if @dictionary_entries.key?(table_name)

      @dictionary_entries[table_name] = Gitlab::Database::Dictionary.entries.find_by_table_name(table_name)
    end

    def test_db_connection
      return @test_db_connection if defined?(@test_db_connection)

      # rubocop:disable Database/EstablishConnection -- The Keep operates against the test DB only.
      @test_db_connection = ActiveRecord::Base
        .establish_connection(ActiveRecord::Base.configurations.find_db_config('test'))
        .lease_connection
      # rubocop:enable Database/EstablishConnection
    end

    def reset_db
      ApplicationRecord.connection_handler.clear_all_connections!
      ::Gitlab::Housekeeper::Shell.execute('rails', 'db:reset', env: { 'RAILS_ENV' => 'test' })
    end

    def migrate
      ::Gitlab::Housekeeper::Shell.execute('rails', 'db:migrate', env: { 'RAILS_ENV' => 'test' })
    end

    def groups_helper
      ::Keeps::Helpers::Groups.instance
    end

    def grafana_query
      @grafana_query ||= ::Keeps::Helpers::GrafanaUnusedIndexQuery.new
    end

    def keep_list
      @keep_list ||= ::Keeps::Helpers::IndexKeepList.new
    end

    def foreign_key_indexes
      @foreign_key_indexes ||= ForeignKeyIndexes.new(test_db_connection)
    end

    def migration_builder
      @migration_builder ||= MigrationBuilder.new
    end

    def cluster_mapper
      @cluster_mapper ||= InstanceClusterMapper.new
    end
  end
end

require_relative 'cleanup_unused_indexes/foreign_key_indexes'
require_relative 'cleanup_unused_indexes/instance_cluster_mapper'
require_relative 'cleanup_unused_indexes/migration_builder'
