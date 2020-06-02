# frozen_string_literal: true

module Gitlab
  module JiraImport
    JIRA_IMPORT_CACHE_TIMEOUT = 10.seconds.to_i

    FAILED_ISSUES_COUNTER_KEY = 'jira-import/failed/%{project_id}/%{collection_type}'
    NEXT_ITEMS_START_AT_KEY = 'jira-import/paginator/%{project_id}/%{collection_type}'
    JIRA_IMPORT_LABEL = 'jira-import/import-label/%{project_id}'
    ITEMS_MAPPER_CACHE_KEY = 'jira-import/items-mapper/%{project_id}/%{collection_type}/%{jira_isssue_id}'
    ALREADY_IMPORTED_ITEMS_CACHE_KEY = 'jira-importer/already-imported/%{project}/%{collection_type}'

    def self.validate_project_settings!(project, user: nil)
      if user
        raise Projects::ImportService::Error, _('Cannot import because issues are not available in this project.') unless project.feature_available?(:issues, user)
        raise Projects::ImportService::Error, _('You do not have permissions to run the import.') unless user.can?(:admin_project, project)
      end

      jira_service = project.jira_service

      raise Projects::ImportService::Error, _('Jira integration not configured.') unless jira_service&.active?
      raise Projects::ImportService::Error, _('Unable to connect to the Jira instance. Please check your Jira integration configuration.') unless jira_service.test(nil)[:success]
    end

    def self.jira_issue_cache_key(project_id, jira_issue_id)
      ITEMS_MAPPER_CACHE_KEY % { project_id: project_id, collection_type: :issues, jira_isssue_id: jira_issue_id }
    end

    def self.already_imported_cache_key(collection_type, project_id)
      ALREADY_IMPORTED_ITEMS_CACHE_KEY % { collection_type: collection_type, project: project_id }
    end

    def self.jira_issues_next_page_cache_key(project_id)
      NEXT_ITEMS_START_AT_KEY % { project_id: project_id, collection_type: :issues }
    end

    def self.failed_issues_counter_cache_key(project_id)
      FAILED_ISSUES_COUNTER_KEY % { project_id: project_id, collection_type: :issues }
    end

    def self.import_label_cache_key(project_id)
      JIRA_IMPORT_LABEL % { project_id: project_id }
    end

    def self.increment_issue_failures(project_id)
      cache_class.increment(self.failed_issues_counter_cache_key(project_id))
    end

    def self.issue_failures(project_id)
      cache_class.read(self.failed_issues_counter_cache_key(project_id)).to_i
    end

    def self.get_issues_next_start_at(project_id)
      cache_class.read(self.jira_issues_next_page_cache_key(project_id)).to_i
    end

    def self.store_issues_next_started_at(project_id, value)
      cache_key = self.jira_issues_next_page_cache_key(project_id)
      cache_class.write(cache_key, value)
    end

    def self.cache_issue_mapping(issue_id, jira_issue_id, project_id)
      cache_key = JiraImport.jira_issue_cache_key(project_id, jira_issue_id)
      cache_class.write(cache_key, issue_id)
    end

    def self.get_import_label_id(project_id)
      cache_class.read(JiraImport.import_label_cache_key(project_id))
    end

    def self.cache_import_label_id(project_id, label_id)
      cache_class.write(JiraImport.import_label_cache_key(project_id), label_id)
    end

    def self.cache_cleanup(project_id)
      cache_class.expire(self.import_label_cache_key(project_id), JIRA_IMPORT_CACHE_TIMEOUT)
      cache_class.expire(self.failed_issues_counter_cache_key(project_id), JIRA_IMPORT_CACHE_TIMEOUT)
      cache_class.expire(self.jira_issues_next_page_cache_key(project_id), JIRA_IMPORT_CACHE_TIMEOUT)
      cache_class.expire(self.already_imported_cache_key(:issues, project_id), JIRA_IMPORT_CACHE_TIMEOUT)
    end

    def self.cache_class
      Gitlab::Cache::Import::Caching
    end
  end
end
