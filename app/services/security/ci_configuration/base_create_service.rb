# frozen_string_literal: true

module Security
  module CiConfiguration
    CiContentParseError = Class.new(StandardError)

    class BaseCreateService
      attr_reader :branch_name, :current_user, :project, :name

      def initialize(project, current_user)
        @project = project
        @current_user = current_user
        @branch_name = project.repository.next_branch(next_branch)
      end

      def execute
        if project.repository.empty? && !(@params && @params[:initialize_with_sast])
          docs_link = ActionController::Base.helpers.link_to(
            _('add at least one file to the repository'),
            Rails.application.routes.url_helpers.help_page_url(
              'user/project/repository/_index.md', anchor: 'add-files-to-a-repository'
            ),
            target: '_blank',
            rel: 'noopener noreferrer'
          )

          return ServiceResponse.error(
            message: _(format('You must %s before using Security features.', docs_link)).html_safe
          )
        end

        project.repository.add_branch(current_user, branch_name, project.default_branch)

        attributes_for_commit = attributes

        result = ::Files::MultiService.new(project, current_user, attributes_for_commit).execute

        return ServiceResponse.error(message: result[:message]) unless result[:status] == :success

        track_event(attributes_for_commit)
        ServiceResponse.success(payload: { branch: branch_name, success_path: successful_change_path })
      rescue CiContentParseError => e
        Gitlab::ErrorTracking.track_exception(e)

        ServiceResponse.error(message: e.message)
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
        root_ref = root_ref_sha(project.repository)
        return if root_ref.nil?

        @gitlab_ci_yml ||= project.ci_config_for(root_ref)
        YAML.safe_load(@gitlab_ci_yml) if @gitlab_ci_yml
      rescue Psych::BadAlias
        raise CiContentParseError, _(".gitlab-ci.yml with aliases/anchors is not supported. " \
                                     "Please change the CI configuration manually.")
      rescue Psych::Exception => e
        Gitlab::AppLogger.error("Failed to process existing .gitlab-ci.yml: #{e.message}")

        raise CiContentParseError, "#{name} merge request creation failed"
      end

      def successful_change_path
        merge_request_params = { source_branch: branch_name, description: description }
        Gitlab::Routing.url_helpers.project_new_merge_request_url(project, merge_request: merge_request_params)
      end

      def remove_branch_on_exception
        return unless project.repository.branch_exists?(branch_name)

        target_sha = project.repository.commit(branch_name).sha
        project.repository.rm_branch(current_user, branch_name, target_sha: target_sha)
      end

      def track_event(attributes_for_commit)
        action = attributes_for_commit[:actions].first

        Gitlab::Tracking.event(
          self.class.to_s, action[:action], label: action[:default_values_overwritten].to_s
        )
      end

      def root_ref_sha(repository)
        commit = repository.commit(repository.root_ref)

        commit&.sha
      end
    end
  end
end
