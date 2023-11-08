# frozen_string_literal: true

module Gitlab
  module Database
    class Dictionary
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

      def view_name
        data['view_name']
      end

      def milestone
        data['milestone']
      end

      def gitlab_schema
        data['gitlab_schema']
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

      attr_reader :file_path, :data

      def help_page_url
        # rubocop:disable Gitlab/DocUrl -- link directly to docs.gitlab.com, always
        'https://docs.gitlab.com/ee/development/database/database_dictionary.html'
        # rubocop:enable Gitlab/DocUrl
      end
    end
  end
end
