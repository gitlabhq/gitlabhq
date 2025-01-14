# frozen_string_literal: true

module Gitlab
  module Database
    class Dictionary
      include Enumerable

      delegate :each, to: :@dictionary_entries

      ALL_SCOPES = ['', 'views', 'deleted_tables'].freeze

      def initialize(dictionary_entries)
        @dictionary_entries = dictionary_entries
      end

      def to_name_and_schema_mapping
        @dictionary_entries.map(&:name_and_schema).to_h
      end

      def find_by_table_name(name)
        @dictionary_entries.find { |entry| entry.key_name == name }
      end

      def find_all_by_schema(schema_name)
        @dictionary_entries.select { |entry| entry.schema?(schema_name) }
      end

      def find_all_having_desired_sharding_key_migration_job
        @dictionary_entries.select { |entry| entry.desired_sharding_key_migration_job_name.present? }
      end

      def self.entries(scope = '')
        @entries ||= {}
        @entries[scope] ||= new(
          Dir.glob(dictionary_path_globs(scope)).map do |file_path|
            Entry.new(file_path).tap(&:validate!)
          end
        )
      end

      def self.any_entry(name)
        ALL_SCOPES.each do |scope|
          e = entry(name, scope)
          return e if e
        end

        nil
      end

      def self.entry(name, scope = '')
        entries(scope).find_by_table_name(name)
      end

      private_class_method def self.dictionary_path_globs(scope)
        dictionary_paths.map { |path| Rails.root.join(path, scope, '*.yml') }
      end

      private_class_method def self.dictionary_paths
        ::Gitlab::Database.all_database_connections
                          .values.map(&:db_docs_dir).uniq
      end

      class Entry
        def initialize(file_path)
          @file_path = file_path
          @data = YAML.load_file(file_path)
        end

        def name_and_schema
          [key_name, gitlab_schema.to_sym]
        end

        def table_name
          data['table_name']
        end

        def feature_categories
          data['feature_categories']
        end

        def view_name
          data['view_name']
        end

        def milestone
          data['milestone']
        end

        def milestone_greater_than_or_equal_to?(other_milestone)
          # some tables have milestones denoted as <6.0 or TODO, which are not clean milestones.
          # For these tables, we just return `false` as these are probably older tables and we needn't run checks.
          return false if not_having_a_clean_milestone?

          # we use Gem::Version to compare version numbers correctly
          my_milestone = Gem::Version.new(milestone.to_s)
          other_milestone = Gem::Version.new(other_milestone.to_s)

          my_milestone >= other_milestone
        end

        def gitlab_schema
          data['gitlab_schema']
        end

        def table_size
          data['table_size'] || 'unknown'
        end

        def sharding_key
          data['sharding_key']
        end

        def desired_sharding_key
          data['desired_sharding_key']
        end

        def sharding_key_issue_url
          data['sharding_key_issue_url']
        end

        def exempt_from_sharding?
          !!data['exempt_from_sharding']
        end

        def classes
          data['classes']
        end

        def allow_cross_to_schemas(type)
          data["allow_cross_#{type}"].to_a.map(&:to_sym)
        end

        def desired_sharding_key_migration_job_name
          data['desired_sharding_key_migration_job_name']
        end

        def schema?(schema_name)
          gitlab_schema == schema_name.to_s
        end

        def key_name
          table_name || view_name
        end

        def validate!
          return true unless gitlab_schema.nil?

          raise(
            GitlabSchema::UnknownSchemaError,
            "#{file_path} must specify a valid gitlab_schema for #{key_name}. " \
              "See #{help_page_url}"
          )
        end

        private

        def not_having_a_clean_milestone?
          milestone.to_s == 'TODO' || milestone.to_s.start_with?('<')
        end

        attr_reader :file_path, :data

        def help_page_url
          # rubocop:disable Gitlab/DocumentationLinks/HardcodedUrl -- link directly to docs.gitlab.com, always
          'https://docs.gitlab.com/ee/development/database/database_dictionary.html'
          # rubocop:enable Gitlab/DocumentationLinks/HardcodedUrl
        end
      end
    end
  end
end
