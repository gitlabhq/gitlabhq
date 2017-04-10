# Check a user's access to perform a git action. All public methods in this
# class return an instance of `GitlabAccessStatus`
module Gitlab
  class GitAccess
    include ActionView::Helpers::SanitizeHelper
    include PathLocksHelper
    UnauthorizedError = Class.new(StandardError)

    ERROR_MESSAGES = {
      upload: 'You are not allowed to upload code for this project.',
      download: 'You are not allowed to download code from this project.',
      deploy_key_upload:
        'This deploy key does not have write access to this project.',
      no_repo: 'A repository for this project does not exist yet.'
    }.freeze

    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }.freeze
    PUSH_COMMANDS = %w{ git-receive-pack }.freeze
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
      check_active_user!
      check_project_accessibility!
      check_command_existence!(cmd)
      check_repository_existence!

      check_geo_license!

      case cmd
      when *DOWNLOAD_COMMANDS
        check_download_access!
      when *PUSH_COMMANDS
        check_push_access!(changes)
      end

      build_status_object(true)
    rescue UnauthorizedError => ex
      build_status_object(false, ex.message)
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
      return if deploy_key? || geo_node_key?

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

    def check_geo_license!
      if Gitlab::Geo.secondary? && !Gitlab::Geo.license_allows?
        raise UnauthorizedError, 'Your current license does not have GitLab Geo add-on enabled.'
      end
    end

    def check_repository_existence!
      unless project.repository.exists?
        raise UnauthorizedError, ERROR_MESSAGES[:no_repo]
      end
    end

    def check_download_access!
      return if deploy_key? || geo_node_key?

      passed = user_can_download_code? ||
        build_can_download_code? ||
        guest_can_download_code?

      unless passed
        raise UnauthorizedError, ERROR_MESSAGES[:download]
      end
    end

    # TODO: please clean this up
    def check_push_access!(changes)
      if project.repository_read_only?
        raise UnauthorizedError, 'The repository is temporarily read-only. Please try again later.'
      end

      if Gitlab::Geo.secondary?
        raise UnauthorizedError, "You can't push code on a secondary GitLab Geo node."
      end

      if deploy_key
        check_deploy_key_push_access!
      elsif user
        check_user_push_access!
      else
        raise UnauthorizedError, ERROR_MESSAGES[:upload]
      end

      return if changes.blank? # Allow access.

      if project.above_size_limit?
        raise UnauthorizedError, Gitlab::RepositorySizeError.new(project).push_error
      end

      if ::License.block_changes?
        message = ::LicenseHelper.license_message(signed_in: true, is_admin: (user && user.admin?))
        raise UnauthorizedError, strip_tags(message)
      end

      check_change_access!(changes)
    end

    def check_user_push_access!
      unless authentication_abilities.include?(:push_code)
        raise UnauthorizedError, ERROR_MESSAGES[:upload]
      end
    end

    def check_deploy_key_push_access!
      unless deploy_key.can_push_to?(project)
        raise UnauthorizedError, ERROR_MESSAGES[:deploy_key_upload]
      end
    end

    def check_change_access!(changes)
      changes_list = Gitlab::ChangesList.new(changes)

      push_size_in_bytes = 0

      # Iterate over all changes to find if user allowed all of them to be applied
      changes_list.each do |change|
        status = check_single_change_access(change)

        unless status.allowed?
          # If user does not have access to make at least one change - cancel all push
          raise UnauthorizedError, status.message
        end

        if project.size_limit_enabled?
          push_size_in_bytes += EE::Gitlab::Deltas.delta_size_check(change, project.repository)
        end
      end

      if project.changes_will_exceed_size_limit?(push_size_in_bytes)
        raise UnauthorizedError, Gitlab::RepositorySizeError.new(project).new_changes_error
      end
    end

    def check_single_change_access(change)
      Checks::ChangeAccess.new(
        change,
        user_access: user_access,
        project: project,
        skip_authorization: deploy_key?,
        protocol: protocol
      ).exec
    end

    def deploy_key
      actor if deploy_key?
    end

    def deploy_key?
      actor.is_a?(DeployKey)
    end

    def geo_node_key
      actor if geo_node_key?
    end

    def geo_node_key?
      actor.is_a?(GeoNodeKey)
    end

    def can_read_project?
      if deploy_key?
        deploy_key.has_access_to?(project)
      elsif geo_node_key?
        true
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
        when DeployKey
          nil
        when GeoNodeKey
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
