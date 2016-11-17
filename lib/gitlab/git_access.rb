# Check a user's access to perform a git action. All public methods in this
# class return an instance of `GitlabAccessStatus`
module Gitlab
  class GitAccess
    UnauthorizedError = Class.new(StandardError)

    ERROR_MESSAGES = {
      upload: 'You are not allowed to upload code for this project.',
      download: 'You are not allowed to download code from this project.',
      deploy_key: 'This deploy key does not have write access to this project.',
      no_repo: 'A repository for this project does not exist yet.'
    }

    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }
    PUSH_COMMANDS = %w{ git-receive-pack }
    ALL_COMMANDS = DOWNLOAD_COMMANDS + PUSH_COMMANDS

    attr_reader :actor, :project, :protocol, :user_access, :authentication_abilities

    def initialize(actor, project, protocol, authentication_abilities:)
      @actor    = actor
      @project  = project
      @protocol = protocol
      @authentication_abilities = authentication_abilities
      @user_access = UserAccess.new(user, project: project)
    end

    def check(cmd, changes)
      check_protocol!
      check_active_user! unless deploy_key?
      check_project_accessibility!
      check_command_existence!(cmd)

      case cmd
      when *DOWNLOAD_COMMANDS
        download_access_check
      when *PUSH_COMMANDS
        push_access_check(changes)
      end

      build_status_object(true)
    rescue UnauthorizedError => ex
      build_status_object(false, ex.message)
    end

    def download_access_check
      if deploy_key
        deploy_key.has_access_to?(project)
      elsif user
        user_download_access_check
      end ||
        Guest.can?(:download_code, project) ||
        raise(UnauthorizedError, ERROR_MESSAGES[:download])
    end

    def push_access_check(changes)
      if deploy_key
        deploy_key_push_access_check(changes)
      elsif user
        user_push_access_check(changes)
      else
        raise UnauthorizedError, ERROR_MESSAGES[:upload]
      end
    end

    def user_download_access_check
      unless user_can_download_code? || build_can_download_code?
        raise UnauthorizedError, ERROR_MESSAGES[:download]
      end
    end

    def user_can_download_code?
      authentication_abilities.include?(:download_code) && user_access.can_do_action?(:download_code)
    end

    def build_can_download_code?
      authentication_abilities.include?(:build_download_code) && user_access.can_do_action?(:build_download_code)
    end

    def user_push_access_check(changes)
      unless authentication_abilities.include?(:push_code)
        raise UnauthorizedError, ERROR_MESSAGES[:upload]
      end

      if changes.blank?
        return # Allow access.
      end

      check_repository_existence!
      check_change_access!(changes)
    end

    def deploy_key_push_access_check(changes)
      if deploy_key.can_push_to?(project)
        check_repository_existence!
        check_change_access!(changes)
      else
        raise UnauthorizedError, ERROR_MESSAGES[:deploy_key]
      end
    end

    def protocol_allowed?
      Gitlab::ProtocolAccess.allowed?(protocol)
    end

    private

    def check_protocol!
      unless protocol_allowed?
        raise UnauthorizedError, "Git access over #{protocol.upcase} is not allowed"
      end
    end

    def check_active_user!
      if user && !user_access.allowed?
        raise UnauthorizedError, "Your account has been blocked."
      end
    end

    def check_project_accessibility!
      if project.blank? || !can_read_project?
        raise UnauthorizedError, 'The project you were looking for could not be found.'
      end
    end

    def check_command_existence!(cmd)
      unless ALL_COMMANDS.include?(cmd)
        raise UnauthorizedError, "The command you're trying to execute is not allowed."
      end
    end

    def check_repository_existence!
      unless project.repository.exists?
        raise UnauthorizedError, ERROR_MESSAGES[:no_repo]
      end
    end

    def check_change_access!(changes)
      changes_list = Gitlab::ChangesList.new(changes)

      # Iterate over all changes to find if user allowed all of them to be applied
      changes_list.each do |change|
        status = check_single_change_access(change)
        unless status.allowed?
          # If user does not have access to make at least one change - cancel all push
          raise UnauthorizedError, status.message
        end
      end
    end

    def check_single_change_access(change)
      Checks::ChangeAccess.new(
        change,
        user_access: user_access,
        project: project,
        skip_authorization: deploy_key?).exec
    end

    def matching_merge_request?(newrev, branch_name)
      Checks::MatchingMergeRequest.new(newrev, branch_name, project).match?
    end

    def deploy_key
      actor if deploy_key?
    end

    def deploy_key?
      actor.is_a?(DeployKey)
    end

    def can_read_project?
      if deploy_key
        deploy_key.has_access_to?(project)
      elsif user
        user.can?(:read_project, project)
      end || Guest.can?(:read_project, project)
    end

    protected

    def user
      return @user if defined?(@user)

      @user =
        case actor
        when User
          actor
        when Key
          actor.user
        end
    end

    def build_status_object(status, message = '')
      Gitlab::GitAccessStatus.new(status, message)
    end
  end
end
