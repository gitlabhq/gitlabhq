# Check a user's access to perform a git action. All public methods in this
# class return an instance of `GitlabAccessStatus`
module Gitlab
  class GitAccess
    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }
    PUSH_COMMANDS = %w{ git-receive-pack }

    attr_reader :actor, :project, :protocol, :user_access, :access_type

    def initialize(actor, project, protocol, access_type: access_type)
      @actor    = actor
      @project  = project
      @protocol = protocol
      @access_type = access_type
      @user_access = UserAccess.new(user, project: project)
    end

    def check(cmd, changes)
      return build_status_object(false, "Git access over #{protocol.upcase} is not allowed") unless protocol_allowed?

      unless actor
        return build_status_object(false, "No user or key was provided.")
      end

      if user && !user_access.allowed?
        return build_status_object(false, "Your account has been blocked.")
      end

      unless project && (user_access.can_read_project? || deploy_key_can_read_project?)
        return build_status_object(false, 'The project you were looking for could not be found.')
      end

      case cmd
      when *DOWNLOAD_COMMANDS
        download_access_check
      when *PUSH_COMMANDS
        push_access_check(changes)
      else
        build_status_object(false, "The command you're trying to execute is not allowed.")
      end
    end

    def download_access_check
      if user
        user_download_access_check
      elsif deploy_key
        build_status_object(true)
      else
        raise 'Wrong actor'
      end
    end

    def push_access_check(changes)
      if user
        user_push_access_check(changes)
      elsif deploy_key
        build_status_object(false, "Deploy keys are not allowed to push code.")
      else
        raise 'Wrong actor'
      end
    end

    def user_download_access_check
      unless privileged_user_can_download_code? || restricted_user_can_download_code?
        return build_status_object(false, "You are not allowed to download code from this project.")
      end

      build_status_object(true)
    end

    def privileged_user_can_download_code?
      access_type == :full && user_access.can_do_action?(:download_code)
    end

    def restricted_user_can_download_code?
      access_type == :restricted && user_access.can_do_action?(:restricted_download_code)
    end

    def user_push_access_check(changes)
      unless access_type == :full
        return build_status_object(false, "You are not allowed to upload code for this project.")
      end

      if changes.blank?
        return build_status_object(true)
      end

      unless project.repository.exists?
        return build_status_object(false, "A repository for this project does not exist yet.")
      end

      changes_list = Gitlab::ChangesList.new(changes)

      # Iterate over all changes to find if user allowed all of them to be applied
      changes_list.each do |change|
        status = change_access_check(change)
        unless status.allowed?
          # If user does not have access to make at least one change - cancel all push
          return status
        end
      end

      build_status_object(true)
    end

    def change_access_check(change)
      Checks::ChangeAccess.new(change, user_access: user_access, project: project).exec
    end

    def protocol_allowed?
      Gitlab::ProtocolAccess.allowed?(protocol)
    end

    private

    def matching_merge_request?(newrev, branch_name)
      Checks::MatchingMergeRequest.new(newrev, branch_name, project).match?
    end

    def deploy_key
      actor if actor.is_a?(DeployKey)
    end

    def deploy_key_can_read_project?
      if deploy_key
        return true if project.public?
        deploy_key.projects.include?(project)
      else
        false
      end
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
        end
    end

    def build_status_object(status, message = '')
      Gitlab::GitAccessStatus.new(status, message)
    end
  end
end
