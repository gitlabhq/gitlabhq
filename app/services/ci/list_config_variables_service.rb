# frozen_string_literal: true

module Ci
  class ListConfigVariablesService < ::BaseService
    include ReactiveCaching

    self.reactive_cache_key = ->(service) { [service.class.name, service.id] }
    self.reactive_cache_work_type = :no_dependency
    self.reactive_cache_worker_finder = ->(id, *_args) { from_cache(id) }

    def self.from_cache(id)
      project_id, user_id = id.split('-')

      project = Project.find(project_id)
      user = User.find(user_id)

      new(project, user)
    end

    def execute(ref)
      # "ref" is not a enough for a cache key because the name is static but that branch can be changed any time
      sha = project.commit(ref).try(:sha)

      with_reactive_cache(sha, ref) { |result| result }
    end

    def calculate_reactive_cache(sha, ref)
      config = ::Gitlab::Ci::ProjectConfig.new(project: project, sha: sha)

      return empty_config_result unless config.exists?
      return empty_config_result unless project_ref_contains_sha?(sha)

      result = build_ci_config(sha, ref, config)

      result.valid? ? extract_variables(result) : {}
    rescue Gitlab::Ci::Config::ConfigError
      {}
    end

    # Required for ReactiveCaching, it is also used in `reactive_cache_worker_finder`
    def id
      "#{project.id}-#{current_user.id}"
    end

    private

    def build_ci_config(sha, ref, config)
      Gitlab::Ci::Config.new(
        config.content,
        project: project,
        user: current_user,
        sha: sha,
        ref: ref
      )
    end

    # Overridden in EE
    def extract_variables(result)
      result.variables_with_prefill_data
    end

    # Overridden in EE
    def empty_config_result
      {}
    end

    def project_ref_contains_sha?(sha)
      return true unless project && sha && project.repository_exists?

      Rails.cache.fetch(['project', project.id, 'ref/contains/sha', sha], expires_in: 5.minutes) do
        repo = project.repository
        repo.branch_names_contains(sha, limit: 1).any? || repo.tag_names_contains(sha, limit: 1).any?
      end
    end
  end
end

Ci::ListConfigVariablesService.prepend_mod
