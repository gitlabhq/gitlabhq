# frozen_string_literal: true

module Gitlab
  class GitAccessSnippet < GitAccess
    extend ::Gitlab::Utils::Override

    ERROR_MESSAGES = {
      authentication_mechanism: 'The authentication mechanism is not supported.',
      read_snippet: 'You are not allowed to read this snippet.',
      update_snippet: 'You are not allowed to update this snippet.',
      snippet_not_found: 'The snippet you were looking for could not be found.',
      no_repo: 'The snippet repository you were looking for could not be found.'
    }.freeze

    alias_method :snippet, :container

    def initialize(actor, snippet, protocol, **kwargs)
      super(actor, snippet, protocol, **kwargs)

      @auth_result_type = nil
      @authentication_abilities &= [:download_code, :push_code]
    end

    override :project
    def project
      container.project if container.is_a?(ProjectSnippet)
    end

    override :check
    def check(cmd, changes)
      check_snippet_accessibility!

      super.tap do |_|
        # Ensure HEAD points to the default branch in case it is not master
        snippet.change_head_to_default_branch
      end
    end

    override :download_ability
    def download_ability
      :read_snippet
    end

    override :push_ability
    def push_ability
      :update_snippet
    end

    private

    # TODO: Implement EE/Geo https://gitlab.com/gitlab-org/gitlab/issues/205629
    override :check_custom_action
    def check_custom_action
      # snippets never return custom actions, such as geo replication.
    end

    override :check_valid_actor!
    def check_valid_actor!
      # TODO: Investigate if expanding actor/authentication types are needed.
      # https://gitlab.com/gitlab-org/gitlab/issues/202190
      if actor && !allowed_actor?
        raise ForbiddenError, error_message(:authentication_mechanism)
      end

      super
    end

    def allowed_actor?
      actor.is_a?(User) || actor.instance_of?(Key)
    end

    override :check_push_access!
    def check_push_access!
      raise ForbiddenError, error_message(:update_snippet) unless user

      if snippet&.repository_read_only?
        raise ForbiddenError, error_message(:read_only)
      end

      check_change_access!
    end

    def check_snippet_accessibility!
      if snippet.blank?
        raise NotFoundError, error_message(:snippet_not_found)
      end
    end

    override :can_read_project?
    def can_read_project?
      return true if user&.migration_bot?

      super
    end

    override :check_download_access!
    def check_download_access!
      passed = guest_can_download_code? || user_can_download_code?

      unless passed
        raise ForbiddenError, error_message(:read_snippet)
      end
    end

    override :check_change_access!
    def check_change_access!
      unless user_can_push?
        raise ForbiddenError, error_message(:update_snippet)
      end

      check_size_before_push!
      check_access!
      check_push_size!
    end

    override :check_access!
    def check_access!
      changes_list.each do |change|
        # If user does not have access to make at least one change, cancel all
        # push by allowing the exception to bubble up
        Checks::SnippetCheck.new(change, default_branch: snippet.default_branch, root_ref: snippet.repository.root_ref, logger: logger).validate!
        Checks::PushFileCountCheck.new(change, repository: repository, limit: Snippet.max_file_limit, logger: logger).validate!
      end
    rescue Checks::TimedLogger::TimeoutError
      raise TimeoutError, logger.full_message
    end

    override :user_access
    def user_access
      @user_access ||= UserAccessSnippet.new(user, snippet: snippet)
    end

    override :check_size_limit?
    def check_size_limit?
      return false if user&.migration_bot?

      super
    end
  end
end

Gitlab::GitAccessSnippet.prepend_mod_with('Gitlab::GitAccessSnippet')
