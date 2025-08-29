# frozen_string_literal: true

module Preloaders # rubocop: disable Gitlab/BoundedContexts -- will be addressed in #558536
  class RunnerPolicyPreloader
    attr_reader :runners, :current_user

    def initialize(runners, current_user)
      @runners = runners || []
      @current_user = current_user
    end

    def execute
      ActiveRecord::Associations::Preloader.new(
        records: runners,
        associations: [
          groups: [:route],
          projects: [:route],
          owner_runner_project: [project: :route],
          owner_runner_namespace: [namespace: [:route, :namespace_settings_with_ancestors_inherited_settings]]
        ]
      ).call

      ::Preloaders::ProjectPolicyPreloader.new(projects, current_user).execute
      ::Preloaders::GroupPolicyPreloader.new(groups, current_user).execute
    end

    private

    def projects
      runners.flat_map(&:projects).uniq
    end

    def groups
      runners.flat_map(&:groups).uniq
    end
  end
end
