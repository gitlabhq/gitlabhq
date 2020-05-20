# frozen_string_literal: true

module Gitlab
  module JiraImport
    class BaseImporter
      attr_reader :project, :client, :formatter, :jira_project_key, :running_import

      def initialize(project)
        project.validate_jira_import_settings!

        @running_import = project.latest_jira_import
        @jira_project_key = running_import&.jira_project_key

        raise Projects::ImportService::Error, _('Unable to find Jira project to import data from.') unless @jira_project_key

        @project = project
        @client = project.jira_service.client
        @formatter = Gitlab::ImportFormatter.new
      end

      private

      def imported_items_cache_key
        raise NotImplementedError
      end

      def mark_as_imported(id)
        Gitlab::Cache::Import::Caching.set_add(imported_items_cache_key, id)
      end

      def already_imported?(id)
        Gitlab::Cache::Import::Caching.set_includes?(imported_items_cache_key, id)
      end
    end
  end
end
