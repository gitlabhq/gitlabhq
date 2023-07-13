# frozen_string_literal: true

# This module gathers information about table to schema mapping
# to understand table affinity
#
# Each table / view needs to have assigned gitlab_schema. For example:
#
# - gitlab_shared - defines a set of tables that are found on all databases (data accessed is dependent on connection)
# - gitlab_main / gitlab_ci - defines a set of tables that can only exist on a given application database
# - gitlab_geo - defines a set of tables that can only exist on the geo database
# - gitlab_internal - defines all internal tables of Rails and PostgreSQL
#
# All supported GitLab schemas can be viewed in `db/gitlab_schemas/` and `ee/db/gitlab_schemas/`
#
# Tables for the purpose of tests should be prefixed with `_test_my_table_name`

module Gitlab
  module Database
    module GitlabSchema
      UnknownSchemaError = Class.new(StandardError)

      def self.table_schemas!(tables)
        tables.map { |table| table_schema!(table) }.to_set
      end

      # Mainly used for test tables
      # It maps table names prefixes to gitlab_schemas.
      # The order of keys matter. Prefixes that contain other prefixes should come first.
      IMPLICIT_GITLAB_SCHEMAS = {
        '_test_gitlab_main_clusterwide_' => :gitlab_main_clusterwide,
        '_test_gitlab_main_cell_' => :gitlab_main_cell,
        '_test_gitlab_main_' => :gitlab_main,
        '_test_gitlab_ci_' => :gitlab_ci,
        '_test_gitlab_embedding_' => :gitlab_embedding,
        '_test_gitlab_geo_' => :gitlab_geo,
        '_test_gitlab_pm_' => :gitlab_pm,
        '_test_' => :gitlab_shared,
        'pg_' => :gitlab_internal
      }.freeze

      # rubocop:disable Metrics/CyclomaticComplexity
      def self.table_schema(name)
        schema_name, table_name = name.split('.', 2) # Strip schema name like: `public.`

        # Most of names do not have schemas, ensure that this is table
        unless table_name
          table_name = schema_name
          schema_name = nil
        end

        # strip partition number of a form `loose_foreign_keys_deleted_records_1`
        table_name.gsub!(/_[0-9]+$/, '')

        # Tables and views that are properly mapped
        if gitlab_schema = views_and_tables_to_schema[table_name]
          return gitlab_schema
        end

        # Tables and views that are deleted, but we still need to reference them
        if gitlab_schema = deleted_views_and_tables_to_schema[table_name]
          return gitlab_schema
        end

        # Partitions that belong to the CI domain
        if table_name.start_with?('ci_') && gitlab_schema = views_and_tables_to_schema["p_#{table_name}"]
          return gitlab_schema
        end

        # All tables from `information_schema.` are marked as `internal`
        return :gitlab_internal if schema_name == 'information_schema'

        IMPLICIT_GITLAB_SCHEMAS.each do |prefix, gitlab_schema|
          return gitlab_schema if table_name.start_with?(prefix)
        end

        nil
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def self.table_schema!(name)
        # rubocop:disable Gitlab/DocUrl
        self.table_schema(name) || raise(
          UnknownSchemaError,
          "Could not find gitlab schema for table #{name}: Any new or deleted tables must be added to the database dictionary " \
          "See https://docs.gitlab.com/ee/development/database/database_dictionary.html"
        )
        # rubocop:enable Gitlab/DocUrl
      end

      private_class_method def self.cross_access_allowed?(type, table_schemas)
        table_schemas.any? do |schema|
          extra_schemas = table_schemas - [schema]
          extra_schemas -= Gitlab::Database.all_gitlab_schemas[schema]&.public_send(type) || [] # rubocop:disable GitlabSecurity/PublicSend
          extra_schemas.empty?
        end
      end

      def self.cross_joins_allowed?(table_schemas)
        table_schemas.empty? || self.cross_access_allowed?(:allow_cross_joins, table_schemas)
      end

      def self.cross_transactions_allowed?(table_schemas)
        table_schemas.empty? || self.cross_access_allowed?(:allow_cross_transactions, table_schemas)
      end

      def self.cross_foreign_key_allowed?(table_schemas)
        self.cross_access_allowed?(:allow_cross_foreign_keys, table_schemas)
      end

      def self.dictionary_paths
        Gitlab::Database.all_database_connections
          .values.map(&:db_docs_dir).uniq
      end

      def self.dictionary_path_globs(scope)
        self.dictionary_paths.map { |path| Rails.root.join(path, scope, '*.yml') }
      end

      def self.views_and_tables_to_schema
        @views_and_tables_to_schema ||= self.tables_to_schema.merge(self.views_to_schema)
      end

      def self.deleted_views_and_tables_to_schema
        @deleted_views_and_tables_to_schema ||= self.deleted_tables_to_schema.merge(self.deleted_views_to_schema)
      end

      def self.deleted_tables_to_schema
        @deleted_tables_to_schema ||= self.build_dictionary('deleted_tables').to_h
      end

      def self.deleted_views_to_schema
        @deleted_views_to_schema ||= self.build_dictionary('deleted_views').to_h
      end

      def self.tables_to_schema
        @tables_to_schema ||= self.build_dictionary('').to_h
      end

      def self.views_to_schema
        @views_to_schema ||= self.build_dictionary('views').to_h
      end

      def self.schema_names
        @schema_names ||= self.views_and_tables_to_schema.values.to_set
      end

      def self.build_dictionary(scope)
        Dir.glob(dictionary_path_globs(scope)).map do |file_path|
          data = YAML.load_file(file_path)

          key_name = data['table_name'] || data['view_name']

          # rubocop:disable Gitlab/DocUrl
          if data['gitlab_schema'].nil?
            raise(
              UnknownSchemaError,
              "#{file_path} must specify a valid gitlab_schema for #{key_name}. " \
              "See https://docs.gitlab.com/ee/development/database/database_dictionary.html"
            )
          end
          # rubocop:enable Gitlab/DocUrl

          [key_name, data['gitlab_schema'].to_sym]
        end
      end
    end
  end
end

Gitlab::Database::GitlabSchema.prepend_mod
