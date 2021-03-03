# frozen_string_literal: true

module Gitlab
  module Cleanup
    module Redis
      class DescriptionTemplatesCacheKeysPatternBuilder
        # project_ids - a list of project_ids for which to compute description templates cache keys or `:all` to compute
        # a pattern that cover all description templates cache keys.
        #
        # Example
        # * ::Gitlab::Cleanup::Redis::BatchDeleteDescriptionTemplates.new(:all).execute - to get 2
        # patterns for all issue and merge request description templates cache keys.
        #
        # * ::Gitlab::Cleanup::Redis::BatchDeleteDescriptionTemplates.new([1,2,3,4]).execute - to get an array of
        # patterns for each project's issue and merge request description templates cache keys.
        def initialize(project_ids)
          raise ArgumentError.new('project_ids can either be an array of project IDs or :all') if project_ids != :all && !project_ids.is_a?(Array)

          @project_ids = parse_project_ids(project_ids)
        end

        def execute
          case project_ids
          when :all
            all_instance_patterns
          else
            project_patterns
          end
        end

        private

        attr_reader :project_ids

        def parse_project_ids(project_ids)
          return project_ids if project_ids == :all

          project_ids.map { |id| Integer(id) }
        rescue ArgumentError
          raise ArgumentError.new('Invalid Project ID. Please ensure all passed in project ids values are valid integer project ids.')
        end

        def project_patterns
          cache_key_patterns = []
          Project.id_in(project_ids).each_batch do |batch|
            cache_key_patterns << batch.map do |pr|
              next unless pr.repository.exists?

              cache = Gitlab::RepositoryCache.new(pr.repository)

              [repo_issue_templates_cache_key(cache), repo_merge_request_templates_cache_key(cache)]
            end
          end

          cache_key_patterns.flatten.compact
        end

        def all_instance_patterns
          [all_issue_templates_cache_key, all_merge_request_templates_cache_key]
        end

        def issue_templates_cache_key
          Repository::METHOD_CACHES_FOR_FILE_TYPES[:issue_template]
        end

        def merge_request_templates_cache_key
          Repository::METHOD_CACHES_FOR_FILE_TYPES[:merge_request_template]
        end

        def all_issue_templates_cache_key
          "#{Gitlab::Redis::Cache::CACHE_NAMESPACE}:#{issue_templates_cache_key}:*"
        end

        def all_merge_request_templates_cache_key
          "#{Gitlab::Redis::Cache::CACHE_NAMESPACE}:#{merge_request_templates_cache_key}:*"
        end

        def repo_issue_templates_cache_key(cache)
          "#{Gitlab::Redis::Cache::CACHE_NAMESPACE}:#{cache.cache_key(issue_templates_cache_key)}"
        end

        def repo_merge_request_templates_cache_key(cache)
          "#{Gitlab::Redis::Cache::CACHE_NAMESPACE}:#{cache.cache_key(merge_request_templates_cache_key)}"
        end
      end
    end
  end
end
