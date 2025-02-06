# frozen_string_literal: true

# Checks a user's access to perform a git action.
# All public methods in this class return an instance of `GitlabAccessStatus`

module Gitlab
  class GitAccess
    include Gitlab::Utils::StrongMemoize

    ForbiddenError = Class.new(StandardError)
    NotFoundError = Class.new(StandardError)
    TimeoutError = Class.new(StandardError)

    # Use the magic string '_any' to indicate we do not know what the
    # changes are. This is also what gitlab-shell does.
    ANY = '_any'

    ERROR_MESSAGES = {
      upload: 'You are not allowed to upload code for this project.',
      download: 'You are not allowed to download code from this project.',
      auth_upload: 'You are not allowed to upload code.',
      auth_download: 'You are not allowed to download code.',
      deploy_key_upload: 'This deploy key does not have write access to this project.',
      no_repo: 'A repository for this project does not exist yet.',
      project_not_found: "The project you were looking for could not be found or you don't have permission to view it.",
      auth_by_job_token_forbidden: 'Insufficient permissions to pull from the repository of project %{target_project_path}.',
      auth_by_job_token_project_not_in_allowlist: 'Authentication by CI/CD job token not allowed from %{source_project_path} to %{target_project_path}.',
      command_not_allowed: "The command you're trying to execute is not allowed.",
      upload_pack_disabled_over_http: 'Pulling over HTTP is not allowed.',
      receive_pack_disabled_over_http: 'Pushing over HTTP is not allowed.',
      read_only: 'The repository is temporarily read-only. Please try again later.',
      archived: "You can't push code to an archived project.",
      cannot_push_to_read_only: "You can't push code to a read-only GitLab instance.",
      push_code: 'You are not allowed to push code to this project.'
    }.freeze

    INTERNAL_TIMEOUT = 50.seconds.freeze
    LOG_HEADER = <<~MESSAGE
      Push operation timed out

      Timing information for debugging purposes:
    MESSAGE

    DOWNLOAD_COMMANDS = %w[git-upload-pack git-upload-archive].freeze
    PUSH_COMMANDS = %w[git-receive-pack].freeze
    ALL_COMMANDS = DOWNLOAD_COMMANDS + PUSH_COMMANDS

    attr_reader :actor, :protocol, :authentication_abilities,
      :repository_path, :redirected_path, :auth_result_type,
      :cmd, :changes, :push_options, :gitaly_context
    attr_accessor :container

    def self.error_message(key)
      self.ancestors.each do |cls|
        return cls.const_get(:ERROR_MESSAGES, false).fetch(key)
      rescue NameError, KeyError
        next
      end

      raise ArgumentError, "No error message defined for #{key}"
    end

    def initialize(actor, container, protocol, authentication_abilities:, repository_path: nil, redirected_path: nil, auth_result_type: nil, push_options: nil, gitaly_context: nil) # rubocop:disable Metrics/ParameterLists -- it needs a refactoring to resolve
      @actor     = actor
      @container = container
      @protocol  = protocol
      @authentication_abilities = Array(authentication_abilities)
      @repository_path = repository_path
      @redirected_path = redirected_path
      @auth_result_type = auth_result_type
      @push_options = Gitlab::PushOptions.new(push_options)
      @gitaly_context = gitaly_context
    end

    def check(cmd, changes)
      @changes = changes
      @cmd = cmd

      check_protocol!
      check_valid_actor!
      check_active_user!
      check_authentication_abilities!
      check_command_disabled!
      check_command_existence!

      custom_action = check_custom_action
      return custom_action if custom_action

      check_db_accessibility!
      check_container!
      check_repository_existence!

      case cmd
      when *DOWNLOAD_COMMANDS
        check_download_access!
      when *PUSH_COMMANDS
        check_push_access!
      end
      check_additional_conditions!

      success_result
    end

    def logger
      @logger ||= Checks::TimedLogger.new(timeout: INTERNAL_TIMEOUT, header: LOG_HEADER)
    end

    def guest_can_download?
      ::Users::Anonymous.can?(download_ability, container)
    end

    def deploy_key_can_download_code?
      authentication_abilities.include?(:download_code) &&
        deploy_key? &&
        deploy_key.has_access_to?(container) &&
        (project? && repository_access_level != ::Featurable::DISABLED)
    end

    def user_can_download?
      authentication_abilities.include?(:download_code) &&
        user_access.can_do_action?(download_ability)
    end

    # @return [Symbol] the name of a Declarative Policy ability to check
    def download_ability
      raise NotImplementedError
    end

    # @return [Symbol] the name of a Declarative Policy ability to check
    def push_ability
      raise NotImplementedError
    end

    def request_from_ci_build?
      return false unless protocol == 'http'

      auth_result_type == :build || auth_result_type == :ci
    end

    def protocol_allowed?
      Gitlab::ProtocolAccess.allowed?(protocol, project: project)
    end

    private

    # when accessing via the CI_JOB_TOKEN
    def build_can_download_code?
      authentication_abilities.include?(:build_download_code) && user_access.can_do_action?(:build_download_code)
    end

    def build_can_push?
      authentication_abilities.include?(:build_push_code) && user_access.can_do_action?(:build_push_code)
    end

    def build_can_download?
      build_can_download_code?
    end

    def deploy_token_can_download?
      deploy_token?
    end

    # When overriding this method, be careful using super
    # as deploy_token_can_download? and build_can_download?
    # do not consider the download_ability in the inheriting class
    # for deploy tokens and builds
    def can_download?
      deploy_key_can_download_code? ||
        deploy_token_can_download? ||
        build_can_download? ||
        user_can_download? ||
        guest_can_download?
    end

    def check_container!
      # Strict nil check, to avoid any surprises with Object#present?
      # which can delegate to #empty?
      raise NotFoundError, not_found_message if container.nil?

      check_project! if project?
      add_container_moved_message!
    end

    def check_project!
      check_project_accessibility!
    end

    def check_custom_action
      # no-op: Overridden in EE
    end

    def check_for_console_messages
      return console_messages unless key?

      key_status = Gitlab::Auth::KeyStatusChecker.new(actor)

      if key_status.show_console_message?
        console_messages.push(key_status.console_message)
      else
        console_messages
      end
    end

    def console_messages
      []
    end

    def check_valid_actor!
      return unless key?

      if !actor.valid?
        raise ForbiddenError, "Your SSH key #{actor.errors[:key].first}."
      elsif actor.expired?
        raise ForbiddenError, "Your SSH key has expired."
      end
    end

    def check_protocol!
      return if request_from_ci_build?

      unless protocol_allowed?
        raise ForbiddenError, "Git access over #{protocol.upcase} is not allowed"
      end
    end

    def check_active_user!
      return unless user

      unless user_access.allowed?
        message = Gitlab::Auth::UserAccessDeniedReason.new(user).rejection_message
        raise ForbiddenError, message
      end
    end

    def check_authentication_abilities!
      case cmd
      when *DOWNLOAD_COMMANDS
        unless authentication_abilities.include?(:download_code) || authentication_abilities.include?(:build_download_code)
          raise ForbiddenError, error_message(:auth_download)
        end
      when *PUSH_COMMANDS
        unless authentication_abilities.include?(:push_code) || authentication_abilities.include?(:build_push_code)
          raise ForbiddenError, error_message(:auth_upload)
        end
      end
    end

    def check_project_accessibility!
      return if can_read_project?

      if user&.from_ci_job_token?

        policy = ProjectPolicy.new(user, project)

        if policy.project_allowed_for_job_token?
          raise ForbiddenError, format(error_message(:auth_by_job_token_forbidden), target_project_path: project.path)
        else
          source_project = user.ci_job_token_scope.current_project

          raise ForbiddenError, format(error_message(:auth_by_job_token_project_not_in_allowlist), source_project_path: source_project.path, target_project_path: project.path)
        end
      else
        raise NotFoundError, not_found_message
      end
    end

    def not_found_message
      error_message(:project_not_found)
    end

    def add_container_moved_message!
      return if redirected_path.nil?

      container_moved = Checks::ContainerMoved.new(repository, user, protocol, redirected_path)

      container_moved.add_message
    end

    def check_command_disabled!
      if upload_pack?
        check_upload_pack_disabled!
      elsif receive_pack?
        check_receive_pack_disabled!
      end
    end

    def check_upload_pack_disabled!
      if http? && upload_pack_disabled_over_http?
        raise ForbiddenError, error_message(:upload_pack_disabled_over_http)
      end
    end

    def check_receive_pack_disabled!
      if http? && receive_pack_disabled_over_http?
        raise ForbiddenError, error_message(:receive_pack_disabled_over_http)
      end
    end

    def check_command_existence!
      unless ALL_COMMANDS.include?(cmd)
        raise ForbiddenError, error_message(:command_not_allowed)
      end
    end

    def check_db_accessibility!
      return unless receive_pack?

      if Gitlab::Database.read_only?
        raise ForbiddenError, push_to_read_only_message
      end
    end

    def check_repository_existence!
      raise NotFoundError, no_repo_message unless repository.exists?
    end

    def no_repo_message
      error_message(:no_repo)
    end

    def check_download_access!
      return if can_download?

      raise ForbiddenError, download_forbidden_message
    end

    def download_forbidden_message
      error_message(:download)
    end

    def project?
      # Strict nil check, to avoid any surprises with Object#present?
      # which can delegate to #empty?
      !project.nil?
    end

    def project
      container if container.is_a?(::Project)
    end

    def check_push_access!
      if project&.repository_read_only?
        raise ForbiddenError, error_message(:read_only)
      end

      if project&.archived?
        raise ForbiddenError, error_message(:archived)
      end

      if deploy_key?
        unless deploy_key.can_push_to?(project)
          raise ForbiddenError, error_message(:deploy_key_upload)
        end
      elsif user
        # User access is verified in check_change_access!
      else
        raise ForbiddenError, error_message(:upload)
      end

      check_change_access!
    end

    def user_can_push?
      authentication_abilities.include?(:push_code) &&
        user_access.can_do_action?(push_ability)
    end

    def check_change_access!
      if changes == ANY
        can_push = deploy_key? ||
          build_can_push? ||
          user_can_push? ||
          project&.any_branch_allows_collaboration?(user_access.user)

        unless can_push
          raise ForbiddenError, error_message(:push_code)
        end
      else
        check_access!
      end
    end

    def check_access!
      Checks::ChangesAccess.new(
        changes_list.changes,
        user_access: user_access,
        project: project,
        protocol: protocol,
        logger: logger,
        push_options: push_options,
        gitaly_context: gitaly_context
      ).validate!
    rescue Checks::TimedLogger::TimeoutError
      raise TimeoutError, logger.full_message
    end

    def deploy_key
      actor if deploy_key?
    end

    def deploy_key?
      actor.is_a?(DeployKey) && Gitlab::ExternalAuthorization.allow_deploy_tokens_and_deploy_keys?
    end

    def deploy_token
      actor if deploy_token?
    end

    def deploy_token?
      actor.is_a?(DeployToken) && Gitlab::ExternalAuthorization.allow_deploy_tokens_and_deploy_keys?
    end

    def ci?
      actor == :ci
    end

    def key?
      actor.is_a?(Key)
    end

    def can_read_project?
      if deploy_key?
        deploy_key.has_access_to?(project)
      elsif deploy_token?
        deploy_token.has_access_to?(project)
      elsif user
        user.can?(:read_project, project)
      elsif ci?
        false
      end || ::Users::Anonymous.can?(:read_project, project)
    end

    def http?
      protocol == 'http'
    end

    def ssh?
      protocol == 'ssh'
    end

    def upload_pack?
      cmd == 'git-upload-pack'
    end

    def receive_pack?
      cmd == 'git-receive-pack'
    end

    def upload_pack_disabled_over_http?
      !Gitlab.config.gitlab_shell.upload_pack
    end

    def receive_pack_disabled_over_http?
      !Gitlab.config.gitlab_shell.receive_pack
    end

    protected

    def error_message(key)
      self.class.error_message(key)
    end

    def success_result
      ::Gitlab::GitAccessResult::Success.new(console_messages: check_for_console_messages)
    end

    def changes_list
      @changes_list ||= Gitlab::ChangesList.new(changes == ANY ? [] : changes)
    end

    def user
      strong_memoize(:user) do
        case actor
        when User
          actor
        when DeployKey
          nil
        when Key
          actor.user
        end
      end
    end

    def user_access
      @user_access ||= if ci?
                         CiAccess.new
                       elsif user && request_from_ci_build?
                         BuildAccess.new(user, container: container)
                       elsif deploy_key?
                         DeployKeyAccess.new(deploy_key, container: container)
                       else
                         UserAccess.new(user, container: container)
                       end
    end

    def push_to_read_only_message
      error_message(:cannot_push_to_read_only)
    end

    def repository
      container&.repository
    end

    def check_size_before_push!
      if check_size_limit? && size_checker.above_size_limit?
        raise ForbiddenError, size_checker.error_message.push_error
      end
    end

    def check_push_size!
      return unless check_size_limit?

      # Use #check_repository_disk_size to get correct push size whenever a lot of changes
      # gets pushed at the same time containing the same blobs. This is only
      # doable if GIT_OBJECT_DIRECTORY_RELATIVE env var is set and happens
      # when git push comes from CLI (not via UI and API).
      #
      # Fallback to determining push size using the changes_list so we can still
      # determine the push size if env var isn't set (e.g. changes are made
      # via UI and API).
      if check_quarantine_size?
        check_repository_disk_size
      else
        check_changes_size
      end
    end

    def check_quarantine_size?
      git_env = ::Gitlab::Git::HookEnv.all(repository.gl_repository)

      git_env['GIT_OBJECT_DIRECTORY_RELATIVE'].present?
    end

    def check_repository_disk_size
      check_size_against_limit(repository.object_directory_size)
    end

    def check_changes_size
      revs = ['--not', '--all', '--not']
      revs += changes_list.map { |change| change[:newrev] }

      changes_size = repository.blobs(revs).sum(&:size)

      check_size_against_limit(changes_size)
    end

    def check_size_against_limit(size)
      if size_checker.changes_will_exceed_size_limit?(size, project)
        raise ForbiddenError, size_checker.error_message.new_changes_error
      end
    end

    def check_size_limit?
      strong_memoize(:check_size_limit) do
        changes_list.any? { |change| !Gitlab::Git.blank_ref?(change[:newrev]) }
      end
    end

    def size_checker
      container.repository_size_checker
    end

    # overriden in EE
    def check_additional_conditions!; end

    def repository_access_level
      project&.repository_access_level
    end
  end
end

Gitlab::GitAccess.prepend_mod_with('Gitlab::GitAccess')
