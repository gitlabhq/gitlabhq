# frozen_string_literal: true

module Ci
  module Preloaders
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
            owner_runner_project: [project: [:route, :project_namespace]],
            owner_runner_namespace: [namespace: [:route, :namespace_settings_with_ancestors_inherited_settings]]
          ]
        ).call

        ::Preloaders::ProjectPolicyPreloader.new(projects, current_user).execute
        ::Preloaders::GroupPolicyPreloader.new(groups, current_user).execute

        # `Ci::RunnerPolicy#can_admin_runner` authorizes via `runner.owner`, which is loaded
        # through `owner_runner_project`/`owner_runner_namespace`, not `projects`/`groups`.
        # These return distinct in-memory objects even when they reference the same row, so
        # they need their own policy preload or the ability check re-queries per runner.
        ::Preloaders::ProjectPolicyPreloader.new(owner_projects, current_user).execute
        ::Preloaders::GroupPolicyPreloader.new(owner_groups, current_user).execute
      end

      private

      def projects
        runners.flat_map(&:projects).uniq
      end

      def groups
        runners.flat_map(&:groups).uniq
      end

      def owner_projects
        runners.filter_map { |runner| runner.owner_runner_project&.project }.uniq
      end

      def owner_groups
        runners.filter_map { |runner| runner.owner_runner_namespace&.namespace }.uniq
      end
    end
  end
end
