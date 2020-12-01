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

    def execute(sha)
      with_reactive_cache(sha) { |result| result }
    end

    def calculate_reactive_cache(sha)
      config = project.ci_config_for(sha)
      return {} unless config

      result = Gitlab::Ci::YamlProcessor.new(config, project: project,
                                                     user:    current_user,
                                                     sha:     sha).execute

      result.valid? ? result.variables_with_data : {}
    end

    # Required for ReactiveCaching, it is also used in `reactive_cache_worker_finder`
    def id
      "#{project.id}-#{current_user.id}"
    end
  end
end
