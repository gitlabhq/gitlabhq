# frozen_string_literal: true

require 'cgi'
require_relative 'helpers/groups'
require_relative 'helpers/grafana_unused_index_query'
require_relative 'helpers/index_keep_list'
require_relative 'cleanup_unused_indexes/foreign_key_indexes'
require_relative 'cleanup_unused_indexes/instance_cluster_mapper'
require_relative '../lib/generators/post_deployment_migration/post_deployment_migration_generator'

module Keeps
  # For each PostgreSQL partitioned parent index whose child indexes all show
  # zero activity on GitLab.com, generates a post-deploy migration that
  # removes the parent with `remove_concurrent_partitioned_index_by_name`
  # (cascading to every partition) and yields a Change so the runner opens a
  # merge request.
  #
  # Child partitions of dynamic tables exist only in production, so this keep
  # reads the catalog from a postgres.ai thin clone. It requires
  # `POSTGRES_AI_CONNECTION_STRING` and `POSTGRES_AI_PASSWORD` in addition to
  # the Grafana credentials used by Keeps::CleanupUnusedIndexes:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::CleanupUnusedPartitionedIndexes
  # ```
  class CleanupUnusedPartitionedIndexes < ::Gitlab::Housekeeper::Keep
    MIGRATION_TEMPLATE = 'generator_templates/active_record/migration/'
    FALLBACK_ASSIGNEE_FEATURE_CATEGORY = 'database'

    MIMIR_LOOKBACK_DAYS = Keeps::Helpers::GrafanaUnusedIndexQuery::LOOKBACK_DAYS
    private_constant :MIMIR_LOOKBACK_DAYS

    # The schemas every database connection includes, per
    # db/database_connections/*.yaml. Their tables are never write-locked, so
    # they appear writable on every clone.
    SHARED_GITLAB_SCHEMAS = %w[gitlab_internal gitlab_shared gitlab_shared_org gitlab_shared_cell_local].freeze
    private_constant :SHARED_GITLAB_SCHEMAS

    def each_identified_change
      unless grafana_query.available?
        raise "Grafana credentials missing; cannot detect unused indexes. " \
          "Set #{Keeps::Helpers::GrafanaUnusedIndexQuery::API_URL_ENV}, " \
          "#{Keeps::Helpers::GrafanaUnusedIndexQuery::API_KEY_ENV}, " \
          "#{Keeps::Helpers::GrafanaUnusedIndexQuery::DATASOURCE_UID_ENV}."
      end

      unless CloneCatalog.available?
        raise "postgres.ai clone credentials missing; cannot resolve child partition indexes. " \
          "Set #{Keeps::Helpers::PostgresAi::CONNECTION_STRING_ENV} " \
          "and #{Keeps::Helpers::PostgresAi::PASSWORD_ENV}."
      end

      ensure_test_db!

      clone_catalog.candidate_parent_indexes.each do |index|
        change = build_change_for(index)
        yield(change) if change
      rescue StandardError => e
        @logger.puts "[CleanupUnusedPartitionedIndexes] Skipping #{index.schema}.#{index.name}: " \
          "#{e.class}: #{e.message}"
        next
      end
    ensure
      @clone_catalog&.close
    end

    def make_change!(change)
      ctx = change.context
      ensure_test_db!

      built = migration_builder.build(ctx)

      change.changed_files = [
        built.migration_file,
        built.digest_file
      ]

      # The removal alters the schema, so apply it to regenerate
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

      if keep_list.exempt?(index.schema, index.name)
        return log_decision(index, 'skipped', 'exempt via index_keep_list.yml')
      end

      if foreign_key_indexes.include?("#{index.schema}.#{index.name}")
        return log_decision(index, 'skipped', 'supports a foreign key')
      end

      gitlab_schema = dictionary_entry(index.tablename)&.gitlab_schema
      skip_reason = schema_skip_reason(gitlab_schema)
      return log_decision(index, 'skipped', skip_reason) if skip_reason

      cluster_type = cluster_mapper.for_schema(gitlab_schema)

      children = clone_catalog.child_index_names(index.name)
      return log_decision(index, 'skipped', 'no child partition indexes found on the clone') if children.empty?

      columns = clone_catalog.index_columns(index.name)
      unless rebuildable?(index, columns)
        return log_decision(index, 'skipped',
          'definition has ordering or options the down migration cannot rebuild')
      end

      checked_at = Time.current.utc.iso8601
      return unless all_children_unused?(index, children, cluster_type)

      log_decision(index, 'selected',
        "zero scans across #{children.size} child indexes in the last #{MIMIR_LOOKBACK_DAYS}d on #{cluster_type}; " \
          "proposing removal")

      change = ::Gitlab::Housekeeper::Change.new
      change.identifiers = [self.class.name.demodulize, index.schema, index.name]
      change.context = {
        schema: index.schema,
        name: index.name,
        tablename: index.tablename,
        gitlab_schema: gitlab_schema,
        cluster_type: cluster_type,
        checked_at: checked_at,
        definition: index.definition,
        columns: columns,
        child_index_names: children
      }
      change
    end

    # Candidates come from the production clone, so the parent table can be
    # missing from this checkout's dictionary: a table removed from the
    # codebase keeps existing physically until its drop ships, but its entry
    # lives in db/docs/deleted_tables, which Dictionary.entries excludes. The
    # reverse holds for a table newer than this checkout. Shared-schema tables
    # are writable on every database, so they pass the write-lock scoping on
    # each clone while their usage spans clusters the single-cluster Mimir
    # check never sees. None of these should get an index-removal MR.
    def schema_skip_reason(gitlab_schema)
      return 'table has no db/docs dictionary entry in this checkout' if gitlab_schema.blank?

      return unless SHARED_GITLAB_SCHEMAS.include?(gitlab_schema.to_s)

      "#{gitlab_schema} tables exist on every database; usage cannot be attributed to one cluster"
    end

    # add_concurrent_partitioned_index(table, columns, name:) can only rebuild
    # a plain ascending btree, so anything richer in the definition (DESC,
    # NULLS ordering, opclasses, INCLUDE) would come back wrong on rollback.
    def rebuildable?(index, columns)
      index.definition == "CREATE INDEX #{index.name} ON ONLY " \
        "#{index.schema}.#{index.tablename} USING btree (#{columns.join(', ')})"
    end

    # True only when every currently attached child index has a Mimir series
    # and reports zero scans. In-use indexes are the vast majority and skip
    # silently to keep the job log readable.
    def all_children_unused?(index, children, cluster_type)
      scans = grafana_query.scans_by_index(indexrelnames: children, type: cluster_type)
      return log_decision(index, 'skipped', 'no usage signal from Mimir; skipping conservatively') if scans.nil?

      missing = children - scans.keys
      if missing.any?
        return log_decision(index, 'skipped',
          "no usage signal for #{missing.size} of #{children.size} child indexes; skipping conservatively")
      end

      scans.values.sum == 0
    end

    def log_decision(index, decision, reason)
      @logger.puts(
        "[CleanupUnusedPartitionedIndexes] #{Time.current.utc.iso8601} " \
          "Index \"#{index.name}\" on table \"#{index.tablename}\" was #{decision} with reason: #{reason}"
      )
      nil
    end

    def build_change_details(change, ctx)
      change.title = "Remove unused partitioned index #{ctx[:name]}".truncate(72)
      change.changelog_type = 'other'
      change.labels = labels(ctx[:tablename])
      change.assignees = Array(pick_assignee(ctx[:tablename], change.identifiers))
      change.description = description_for(ctx)
    end

    def description_for(ctx)
      <<~MARKDOWN.chomp
        ## What does this MR do and why?

        Remove the unused partitioned index `#{ctx[:schema]}.#{ctx[:name]}` on
        `#{ctx[:tablename]}` with `remove_concurrent_partitioned_index_by_name`.
        All #{ctx[:child_index_names].size} child partition indexes reported
        **zero scans** over a #{MIMIR_LOOKBACK_DAYS}-day pre-filter window on the
        `#{ctx[:cluster_type]}` Patroni cluster (query run at #{ctx[:checked_at]}).
        Verify the 180-day chart below as confirmation before merging.

        Definition:

        ~~~sql
        #{ctx[:definition]}
        ~~~

        ## :warning: Partitioned removal specifics

        - Dropping the parent index cascades to **every partition** in one
          operation and takes a brief `ACCESS EXCLUSIVE` lock under
          `with_lock_retries`. There is no asynchronous removal path for
          partitioned indexes.
        - On tables with rolling partitions, partitions older than the retention
          window have already been dropped, so the chart below only covers the
          currently attached partitions. Factor the retention period into your
          judgment of the 180-day evidence.

        ## Required: verify the 180-day Grafana chart before merging

        The Keep's #{MIMIR_LOOKBACK_DAYS}-day window is a fast pre-filter, not
        a final verdict. Per
        [Dropping unused indexes](https://docs.gitlab.com/development/database/adding_database_indexes/#dropping-unused-indexes),
        confirm via Grafana over **at least 6 months** before merging.

        [**Open this query in Grafana Explore**](#{grafana_explore_url_for(ctx)}) (6-month range, #{grafana_datasource_uid}).
        The chart should be flat at `0`. The query sums scans across the child
        indexes attached at the time this MR was created:

        #{ctx[:child_index_names].map { |name| "- `#{name}`" }.join("\n")}

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
              sum (
                increase(pg_stat_user_indexes_idx_scan{
                  env="#{grafana_query_env}", type="#{ctx[:cluster_type]}",
                  indexrelname=~"#{ctx[:child_index_names].map { |name| Regexp.escape(name) }.join('|')}"
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

    # Pick one assignee (from the primary feature category) but label across all.
    # The groups helper's reviewer roulette does the picking; this keep assigns
    # the person instead of requesting review.
    def pick_assignee(table_name, identifiers)
      feature_category = dictionary_feature_categories(table_name).first

      groups_helper.pick_reviewer_for_feature_category(
        feature_category, identifiers,
        fallback_feature_category: FALLBACK_ASSIGNEE_FEATURE_CATEGORY
      )
    end

    def labels(table_name)
      group_labels = dictionary_feature_categories(table_name).flat_map do |feature_category|
        groups_helper.labels_for_feature_category(feature_category)
      end.uniq

      group_labels + [
        # Shared with Keeps::CleanupUnusedIndexes so every unused-index MR is
        # collectible in one query.
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
      @foreign_key_indexes ||= ::Keeps::CleanupUnusedIndexes::ForeignKeyIndexes.new(test_db_connection)
    end

    def clone_catalog
      @clone_catalog ||= CloneCatalog.new
    end

    def migration_builder
      @migration_builder ||= MigrationBuilder.new
    end

    def cluster_mapper
      @cluster_mapper ||= ::Keeps::CleanupUnusedIndexes::InstanceClusterMapper.new
    end
  end
end

require_relative 'cleanup_unused_partitioned_indexes/clone_catalog'
require_relative 'cleanup_unused_partitioned_indexes/migration_builder'
