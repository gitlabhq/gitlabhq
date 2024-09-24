# frozen_string_literal: true

module Ci
  class ListConfigVariablesService < ::BaseService
    include ReactiveCaching

    self.reactive_cache_key = ->(service) { [service.class.name, service.id] }
    self.reactive_cache_work_type = :external_dependency
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

      return {} unless config.exists?

      result = execute_yaml_processor(sha, ref, config)

      result.valid? ? result.root_variables_with_prefill_data : {}
    end

    # Required for ReactiveCaching, it is also used in `reactive_cache_worker_finder`
    def id
      "#{project.id}-#{current_user.id}"
    end

    private

    def execute_yaml_processor(sha, ref, config)
      # The `ref` parameter should be branch or tag name. However, the API also accepts a commit SHA and we can't
      # change it to not introduce breaking changes. Instead, here we're checking if a commit SHA is passed
      # as `ref`. If so, we should verify the sha whether it belongs to the project in YamlProcessor.
      sha_passed_as_ref_parameter = !project.repository.branch_or_tag?(ref)

      Gitlab::Ci::YamlProcessor.new(
        config.content,
        project: project,
        user: current_user,
        sha: sha,
        ref: ref,
        verify_project_sha: sha_passed_as_ref_parameter
      ).execute
    end
  end
end
