# Check a user's access to perform a git action. All public methods in this
# class return an instance of `GitlabAccessStatus`
module Gitlab
  class GitAccess
    include ActionView::Helpers::SanitizeHelper
    include PathLocksHelper
    UnauthorizedError = Class.new(StandardError)
    NotFoundError = Class.new(StandardError)
    ProjectMovedError = Class.new(NotFoundError)

    ERROR_MESSAGES = {
      upload: 'You are not allowed to upload code for this project.',
      download: 'You are not allowed to download code from this project.',
      deploy_key_upload:
        'This deploy key does not have write access to this project.',
      no_repo: 'A repository for this project does not exist yet.',
      project_not_found: 'The project you were looking for could not be found.',
      account_blocked: 'Your account has been blocked.',
      command_not_allowed: "The command you're trying to execute is not allowed.",
      upload_pack_disabled_over_http: 'Pulling over HTTP is not allowed.',
      receive_pack_disabled_over_http: 'Pushing over HTTP is not allowed.',
      cannot_push_to_secondary_geo: "You can't push code to a secondary GitLab Geo node."
    }.freeze

    DOWNLOAD_COMMANDS = %w{ git-upload-pack git-upload-archive }.freeze
    PUSH_COMMANDS = %w{ git-receive-pack }.freeze
    ALL_COMMANDS = DOWNLOAD_COMMANDS + PUSH_COMMANDS

    attr_reader :actor, :project, :protocol, :authentication_abilities, :redirected_path

    def initialize(actor, project, protocol, authentication_abilities:, redirected_path: nil)
      @actor    = actor
      @project  = project
      @protocol = protocol
      @redirected_path = redirected_path
      @authentication_abilities = authentication_abilities
    end

    def check(cmd, changes)
      check_protocol!
      check_active_user!
      check_project_accessibility!
      check_project_moved!
      check_command_disabled!(cmd)
      check_command_existence!(cmd)
      check_repository_existence!

      check_geo_license!

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
        raise UnauthorizedError, ERROR_MESSAGES[:account_blocked]
      end
    end

    def check_project_accessibility!
      if project.blank? || !can_read_project?
        raise NotFoundError, ERROR_MESSAGES[:project_not_found]
      end
    end

    def check_project_moved!
      return unless redirected_path

      url = protocol == 'ssh' ? project.ssh_url_to_repo : project.http_url_to_repo
      message = <<-MESSAGE.strip_heredoc
        Project '#{redirected_path}' was moved to '#{project.full_path}'.

        Please update your Git remote and try again:

          git remote set-url origin #{url}
      MESSAGE

      raise ProjectMovedError, message
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
        raise UnauthorizedError, ERROR_MESSAGES[:cannot_push_to_secondary_geo]
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
        # If user does not have access to make at least one change, cancel all
        # push by allowing the exception to bubble up
        check_single_change_access(change)

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

    def ci?
      actor == :ci
    end

    def can_read_project?
      if deploy_key?
        deploy_key.has_access_to?(project)
      elsif geo_node_key?
        true
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
        when GeoNodeKey
          nil
        when Key
          actor.user unless actor.is_a?(DeployKey)
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
  end
end
