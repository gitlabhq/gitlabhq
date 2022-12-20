# frozen_string_literal: true

# This module gathers information about table to schema mapping
# to understand table affinity
#
# Each table / view needs to have assigned gitlab_schema. Names supported today:
#
# - gitlab_shared - defines a set of tables that are found on all databases (data accessed is dependent on connection)
# - gitlab_main / gitlab_ci - defines a set of tables that can only exist on a given application database
# - gitlab_geo - defines a set of tables that can only exist on the geo database
# - gitlab_internal - defines all internal tables of Rails and PostgreSQL
#
# Tables for the purpose of tests should be prefixed with `_test_my_table_name`

module Gitlab
  module Database
    module GitlabSchema
      DICTIONARY_PATH = 'db/docs/'

      # These tables are deleted/renamed, but still referenced by migrations.
      # This is needed for now, but should be removed in the future
      DELETED_TABLES = {
        # main tables
        'alerts_service_data' => :gitlab_main,
        'analytics_devops_adoption_segment_selections' => :gitlab_main,
        'analytics_repository_file_commits' => :gitlab_main,
        'analytics_repository_file_edits' => :gitlab_main,
        'analytics_repository_files' => :gitlab_main,
        'audit_events_archived' => :gitlab_main,
        'backup_labels' => :gitlab_main,
        'clusters_applications_fluentd' => :gitlab_main,
        'forked_project_links' => :gitlab_main,
        'issue_milestones' => :gitlab_main,
        'merge_request_milestones' => :gitlab_main,
        'namespace_onboarding_actions' => :gitlab_main,
        'services' => :gitlab_main,
        'terraform_state_registry' => :gitlab_main,
        'tmp_fingerprint_sha256_migration' => :gitlab_main, # used by lib/gitlab/background_migration/migrate_fingerprint_sha256_within_keys.rb
        'web_hook_logs_archived' => :gitlab_main,
        'vulnerability_export_registry' => :gitlab_main,
        'vulnerability_finding_fingerprints' => :gitlab_main,
        'vulnerability_export_verification_status' => :gitlab_main,

        # CI tables
        'ci_build_trace_sections' => :gitlab_ci,
        'ci_build_trace_section_names' => :gitlab_ci,
        'ci_daily_report_results' => :gitlab_ci,
        'ci_test_cases' => :gitlab_ci,
        'ci_test_case_failures' => :gitlab_ci,

        # leftovers from early implementation of partitioning
        'audit_events_part_5fc467ac26' => :gitlab_main,
        'web_hook_logs_part_0c5294f417' => :gitlab_main
      }.freeze

      def self.table_schemas(tables)
        tables.map { |table| table_schema(table) }.to_set
      end

      def self.table_schema(name, undefined: true)
        schema_name, table_name = name.split('.', 2) # Strip schema name like: `public.`

        # Most of names do not have schemas, ensure that this is table
        unless table_name
          table_name = schema_name
          schema_name = nil
        end

        # strip partition number of a form `loose_foreign_keys_deleted_records_1`
        table_name.gsub!(/_[0-9]+$/, '')

        # Tables that are properly mapped
        if gitlab_schema = views_and_tables_to_schema[table_name]
          return gitlab_schema
        end

        # Tables that are deleted, but we still need to reference them
        if gitlab_schema = DELETED_TABLES[table_name]
          return gitlab_schema
        end

        # All tables from `information_schema.` are marked as `internal`
        return :gitlab_internal if schema_name == 'information_schema'

        return :gitlab_main if table_name.start_with?('_test_gitlab_main_')

        return :gitlab_ci if table_name.start_with?('_test_gitlab_ci_')

        return :gitlab_geo if table_name.start_with?('_test_gitlab_geo_')

        # All tables that start with `_test_` without a following schema are shared and ignored
        return :gitlab_shared if table_name.start_with?('_test_')

        # All `pg_` tables are marked as `internal`
        return :gitlab_internal if table_name.start_with?('pg_')

        # When undefined it's best to return a unique name so that we don't incorrectly assume that 2 undefined schemas belong on the same database
        undefined ? :"undefined_#{table_name}" : nil
      end

      def self.dictionary_path_globs
        [Rails.root.join(DICTIONARY_PATH, '*.yml')]
      end

      def self.view_path_globs
        [Rails.root.join(DICTIONARY_PATH, 'views', '*.yml')]
      end

      def self.views_and_tables_to_schema
        @views_and_tables_to_schema ||= self.tables_to_schema.merge(self.views_to_schema)
      end

      def self.tables_to_schema
        @tables_to_schema ||= Dir.glob(self.dictionary_path_globs).each_with_object({}) do |file_path, dic|
          data = YAML.load_file(file_path)

          dic[data['table_name']] = data['gitlab_schema'].to_sym
        end
      end

      def self.views_to_schema
        @views_to_schema ||= Dir.glob(self.view_path_globs).each_with_object({}) do |file_path, dic|
          data = YAML.load_file(file_path)

          dic[data['view_name']] = data['gitlab_schema'].to_sym
        end
      end

      def self.schema_names
        @schema_names ||= self.views_and_tables_to_schema.values.to_set
      end
    end
  end
end

Gitlab::Database::GitlabSchema.prepend_mod
