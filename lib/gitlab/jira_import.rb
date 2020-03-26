# frozen_string_literal: true

module Gitlab
  module JiraImport
    JIRA_IMPORT_CACHE_TIMEOUT = 10.seconds.to_i

    FAILED_ISSUES_COUNTER_KEY = 'jira-import/failed/%{project_id}/%{collection_type}'
    NEXT_ITEMS_START_AT_KEY = 'jira-import/paginator/%{project_id}/%{collection_type}'
    ITEMS_MAPPER_CACHE_KEY = 'jira-import/items-mapper/%{project_id}/%{collection_type}/%{jira_isssue_id}'
    ALREADY_IMPORTED_ITEMS_CACHE_KEY = 'jira-importer/already-imported/%{project}/%{collection_type}'

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

    def self.increment_issue_failures(project_id)
      Gitlab::Cache::Import::Caching.increment(self.failed_issues_counter_cache_key(project_id))
    end

    def self.get_issues_next_start_at(project_id)
      Gitlab::Cache::Import::Caching.read(self.jira_issues_next_page_cache_key(project_id)).to_i
    end

    def self.store_issues_next_started_at(project_id, value)
      cache_key = self.jira_issues_next_page_cache_key(project_id)
      Gitlab::Cache::Import::Caching.write(cache_key, value)
    end

    def self.cache_cleanup(project_id)
      Gitlab::Cache::Import::Caching.expire(self.failed_issues_counter_cache_key(project_id), JIRA_IMPORT_CACHE_TIMEOUT)
      Gitlab::Cache::Import::Caching.expire(self.jira_issues_next_page_cache_key(project_id), JIRA_IMPORT_CACHE_TIMEOUT)
      Gitlab::Cache::Import::Caching.expire(self.already_imported_cache_key(:issues, project_id), JIRA_IMPORT_CACHE_TIMEOUT)
    end
  end
end
