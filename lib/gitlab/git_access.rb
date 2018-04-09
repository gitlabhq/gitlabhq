# Check a user's access to perform a git action. All public methods in this
# class return an instance of `GitlabAccessStatus`
module Gitlab
  class GitAccess
    include Gitlab::Utils::StrongMemoize

    UnauthorizedError = Class.new(StandardError)
    NotFoundError = Class.new(StandardError)
    ProjectCreationError = Class.new(StandardError)
    ProjectMovedError = Class.new(NotFoundError)

    ERROR_MESSAGES = {
      upload: 'You are not allowed to upload code for this project.',
      download: 'You are not allowed to download code from this project.',
      auth_upload: 'You are not allowed to upload code.',
      auth_download: 'You are not allowed to download code.',
      deploy_key_upload: 'This deploy key does not have write access to this project.',
      no_repo: 'A repository for this project does not exist yet.',
      project_not_found: 'The project you were looking for could not be found.',
      account_blocked: 'Your account has been blocked.',
      command_not_allowed: "The command you're trying to execute is not allowed.",
      upload_pack_disabled_over_http: 'Pulling over HTTP is not allowed.',
      receive_pack_disabled_over_http: 'Pushing over HTTP is not allowed.',
      read_only: 'The repository is temporarily read-only. Please try again later.',
      cannot_push_to_read_only: "You can't push code to a read-only GitLab instance."
    }.freeze

    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }.freeze
    PUSH_COMMANDS = %w{ git-receive-pack }.freeze
    ALL_COMMANDS = DOWNLOAD_COMMANDS + PUSH_COMMANDS

    attr_reader :actor, :project, :protocol, :authentication_abilities, :namespace_path, :project_path, :redirected_path, :auth_result_type

    def initialize(actor, project, protocol, authentication_abilities:, namespace_path: nil, project_path: nil, redirected_path: nil, auth_result_type: nil)
      @actor    = actor
      @project  = project
      @protocol = protocol
      @authentication_abilities = authentication_abilities
      @namespace_path = namespace_path
      @project_path = project_path
      @redirected_path = redirected_path
      @auth_result_type = auth_result_type
    end

    def check(cmd, changes)
      check_protocol!
      check_valid_actor!
      check_active_user!
      check_authentication_abilities!(cmd)
      check_command_disabled!(cmd)
      check_command_existence!(cmd)
      check_db_accessibility!(cmd)

      ensure_project_on_push!(cmd, changes)

      check_project_accessibility!
      add_project_moved_message!
      check_repository_existence!

      case cmd
      when *DOWNLOAD_COMMANDS
        check_download_access!
      when *PUSH_COMMANDS
        check_push_access!(changes)
      end

      true
    end

    def guest_can_download_code?
      Guest.can?(:download_code, project)
    end

    def user_can_download_code?
      authentication_abilities.include?(:download_code) && user_access.can_do_action?(:download_code)
    end

    def build_can_download_code?
      authentication_abilities.include?(:build_download_code) && user_access.can_do_action?(:build_download_code)
    end

    def request_from_ci_build?
      return false unless protocol == 'http'

      auth_result_type == :build || auth_result_type == :ci
    end

    def protocol_allowed?
      Gitlab::ProtocolAccess.allowed?(protocol)
    end

    private

    def check_valid_actor!
      return unless actor.is_a?(Key)

      unless actor.valid?
        raise UnauthorizedError, "Your SSH key #{actor.errors[:key].first}."
      end
    end

    def check_protocol!
      return if request_from_ci_build?

      unless protocol_allowed?
        raise UnauthorizedError, "Git access over #{protocol.upcase} is not allowed"
      end
    end

    def check_active_user!
      if user && !user_access.allowed?
        raise UnauthorizedError, ERROR_MESSAGES[:account_blocked]
      end
    end

    def check_authentication_abilities!(cmd)
      case cmd
      when *DOWNLOAD_COMMANDS
        unless authentication_abilities.include?(:download_code) || authentication_abilities.include?(:build_download_code)
          raise UnauthorizedError, ERROR_MESSAGES[:auth_download]
        end
      when *PUSH_COMMANDS
        unless authentication_abilities.include?(:push_code)
          raise UnauthorizedError, ERROR_MESSAGES[:auth_upload]
        end
      end
    end

    def check_project_accessibility!
      if project.blank? || !can_read_project?
        raise NotFoundError, ERROR_MESSAGES[:project_not_found]
      end
    end

    def add_project_moved_message!
      return if redirected_path.nil?

      project_moved = Checks::ProjectMoved.new(project, user, protocol, redirected_path)

      project_moved.add_message
    end

    def check_command_disabled!(cmd)
      if upload_pack?(cmd)
        check_upload_pack_disabled!
      elsif receive_pack?(cmd)
        check_receive_pack_disabled!
      end
    end

    def check_upload_pack_disabled!
      if http? && upload_pack_disabled_over_http?
        raise UnauthorizedError, ERROR_MESSAGES[:upload_pack_disabled_over_http]
      end
    end

    def check_receive_pack_disabled!
      if http? && receive_pack_disabled_over_http?
        raise UnauthorizedError, ERROR_MESSAGES[:receive_pack_disabled_over_http]
      end
    end

    def check_command_existence!(cmd)
      unless ALL_COMMANDS.include?(cmd)
        raise UnauthorizedError, ERROR_MESSAGES[:command_not_allowed]
      end
    end

    def check_db_accessibility!(cmd)
      return unless receive_pack?(cmd)

      if Gitlab::Database.read_only?
        raise UnauthorizedError, push_to_read_only_message
      end
    end

    def ensure_project_on_push!(cmd, changes)
      return if project || deploy_key?
      return unless receive_pack?(cmd) && changes == '_any' && authentication_abilities.include?(:push_code)

      namespace = Namespace.find_by_full_path(namespace_path)

      return unless user&.can?(:create_projects, namespace)

      project_params = {
        path: project_path,
        namespace_id: namespace.id,
        visibility_level: Gitlab::VisibilityLevel::PRIVATE
      }

      project = Projects::CreateService.new(user, project_params).execute

      unless project.saved?
        raise ProjectCreationError, "Could not create project: #{project.errors.full_messages.join(', ')}"
      end

      @project = project
      user_access.project = @project

      Checks::ProjectCreated.new(project, user, protocol).add_message
    end

    def check_repository_existence!
      unless repository.exists?
        raise NotFoundError, ERROR_MESSAGES[:no_repo]
      end
    end

    def check_download_access!
      passed = deploy_key? ||
        deploy_token? ||
        user_can_download_code? ||
        build_can_download_code? ||
        guest_can_download_code?

      unless passed
        raise UnauthorizedError, ERROR_MESSAGES[:download]
      end
    end

    def check_push_access!(changes)
      if project.repository_read_only?
        raise UnauthorizedError, ERROR_MESSAGES[:read_only]
      end

      if deploy_key?
        unless deploy_key.can_push_to?(project)
          raise UnauthorizedError, ERROR_MESSAGES[:deploy_key_upload]
        end
      elsif user
        # User access is verified in check_change_access!
      else
        raise UnauthorizedError, ERROR_MESSAGES[:upload]
      end

      return if changes.blank? # Allow access this is needed for EE.

      check_change_access!(changes)
    end

    def check_change_access!(changes)
      # If there are worktrees with a HEAD pointing to a non-existent object,
      # calls to `git rev-list --all` will fail in git 2.15+. This should also
      # clear stale lock files.
      project.repository.clean_stale_repository_files

      changes_list = Gitlab::ChangesList.new(changes)

      # Iterate over all changes to find if user allowed all of them to be applied
      changes_list.each.with_index do |change, index|
        first_change = index == 0

        # If user does not have access to make at least one change, cancel all
        # push by allowing the exception to bubble up
        check_single_change_access(change, skip_lfs_integrity_check: !first_change)
      end
    end

    def check_single_change_access(change, skip_lfs_integrity_check: false)
      Checks::ChangeAccess.new(
        change,
        user_access: user_access,
        project: project,
        skip_authorization: deploy_key?,
        skip_lfs_integrity_check: skip_lfs_integrity_check,
        protocol: protocol
      ).exec
    end

    def deploy_key
      actor if deploy_key?
    end

    def deploy_key?
      actor.is_a?(DeployKey)
    end

    def deploy_token
      actor if deploy_token?
    end

    def deploy_token?
      actor.is_a?(DeployToken)
    end

    def ci?
      actor == :ci
    end

    def can_read_project?
      if deploy_key?
        deploy_key.has_access_to?(project)
      elsif deploy_token?
        deploy_token.has_access_to?(project)
      elsif user
        user.can?(:read_project, project)
      elsif ci?
        true # allow CI (build without a user) for backwards compatibility
      end || Guest.can?(:read_project, project)
    end

    def http?
      protocol == 'http'
    end

    def upload_pack?(command)
      command == 'git-upload-pack'
    end

    def receive_pack?(command)
      command == 'git-receive-pack'
    end

    def upload_pack_disabled_over_http?
      !Gitlab.config.gitlab_shell.upload_pack
    end

    def receive_pack_disabled_over_http?
      !Gitlab.config.gitlab_shell.receive_pack
    end

    protected

    def user
      return @user if defined?(@user)

      @user =
        case actor
        when User
          actor
        when DeployKey
          nil
        when Key
          actor.user
        when :ci
          nil
        end
    end

    def user_access
      @user_access ||= if ci?
                         CiAccess.new
                       else
                         UserAccess.new(user, project: project)
                       end
    end

    def push_to_read_only_message
      ERROR_MESSAGES[:cannot_push_to_read_only]
    end

    def repository
      project.repository
    end
  end
end
