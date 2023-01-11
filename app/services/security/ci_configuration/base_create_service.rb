# frozen_string_literal: true

module Security
  module CiConfiguration
    class BaseCreateService
      attr_reader :branch_name, :current_user, :project, :name

      def initialize(project, current_user)
        @project = project
        @current_user = current_user
        @branch_name = project.repository.next_branch(next_branch)
      end

      def execute
        project.repository.add_branch(current_user, branch_name, project.default_branch)

        attributes_for_commit = attributes

        result = ::Files::MultiService.new(project, current_user, attributes_for_commit).execute

        return ServiceResponse.error(message: result[:message]) unless result[:status] == :success

        track_event(attributes_for_commit)
        ServiceResponse.success(payload: { branch: branch_name, success_path: successful_change_path })
      rescue Gitlab::Git::PreReceiveError => e
        ServiceResponse.error(message: e.message)
      rescue StandardError
        remove_branch_on_exception
        raise
      end

      private

      def attributes
        {
          commit_message: message,
          branch_name: branch_name,
          start_branch: branch_name,
          actions: [action]
        }
      end

      def existing_gitlab_ci_content
        root_ref = root_ref_sha(project)
        return if root_ref.nil?

        @gitlab_ci_yml ||= project.ci_config_for(root_ref)
        YAML.safe_load(@gitlab_ci_yml) if @gitlab_ci_yml
      rescue Psych::BadAlias
        raise Gitlab::Graphql::Errors::MutationError,
              ".gitlab-ci.yml with aliases/anchors is not supported. Please change the CI configuration manually."
      rescue Psych::Exception => e
        Gitlab::AppLogger.error("Failed to process existing .gitlab-ci.yml: #{e.message}")
        raise Gitlab::Graphql::Errors::MutationError,
              "#{name} merge request creation mutation failed"
      end

      def successful_change_path
        merge_request_params = { source_branch: branch_name, description: description }
        Gitlab::Routing.url_helpers.project_new_merge_request_url(project, merge_request: merge_request_params)
      end

      def remove_branch_on_exception
        project.repository.rm_branch(current_user, branch_name) if project.repository.branch_exists?(branch_name)
      end

      def track_event(attributes_for_commit)
        action = attributes_for_commit[:actions].first

        Gitlab::Tracking.event(
          self.class.to_s, action[:action], label: action[:default_values_overwritten].to_s
        )
      end

      def root_ref_sha(project)
        project.repository.root_ref_sha
      rescue StandardError => e
        # this might fail on the very first commit,
        # and unfortunately it raises a StandardError
        Gitlab::ErrorTracking.track_exception(e, project_id: project.id)
        nil
      end
    end
  end
end
