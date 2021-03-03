# frozen_string_literal: true

namespace :cache do
  namespace :clear do
    desc "GitLab | Cache | Clear redis cache"
    task redis: :environment do
      cache_key_patterns = %W[
        #{Gitlab::Redis::Cache::CACHE_NAMESPACE}*
        #{Gitlab::Cache::Ci::ProjectPipelineStatus::ALL_PIPELINES_STATUS_PATTERN}
      ]

      ::Gitlab::Cleanup::Redis::BatchDeleteByPattern.new(cache_key_patterns).execute
    end

    desc "GitLab | Cache | Clear description templates redis cache"
    task description_templates: :environment do
      project_ids = Array(ENV['project_ids']&.split(',')).map!(&:squish)

      cache_key_patterns = ::Gitlab::Cleanup::Redis::DescriptionTemplatesCacheKeysPatternBuilder.new(project_ids).execute
      ::Gitlab::Cleanup::Redis::BatchDeleteByPattern.new(cache_key_patterns).execute
    end

    task all: [:redis]
  end

  task clear: 'cache:clear:redis'
end
