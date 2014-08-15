module Gitlab
  module Satellite
    class Action
      DEFAULT_OPTIONS = { git_timeout: Gitlab.config.satellites.timeout.seconds }

      attr_accessor :options, :project, :user

      def initialize(user, project, options = {})
        @options = DEFAULT_OPTIONS.merge(options)
        @project = project
        @user = user
      end

      protected

      # * Sets a 30s timeout for Git
      # * Locks the satellite repo
      # * Yields the prepared satellite repo
      def in_locked_and_timed_satellite
        Gitlab::ShellEnv.set_env(user)

        Grit::Git.with_timeout(options[:git_timeout]) do
          project.satellite.lock do
            return yield project.satellite.repo
          end
        end
      rescue Errno::ENOMEM => ex
        return handle_exception(ex)
      rescue Grit::Git::GitTimeout => ex
        return handle_exception(ex)
      ensure
        Gitlab::ShellEnv.reset_env
      end

      # * Recreates the satellite
      # * Sets up Git variables for the user
      #
      # Note: use this within #in_locked_and_timed_satellite
      def prepare_satellite!(repo)
        project.satellite.clear_and_update!

        repo.config['user.name'] = user.name
        repo.config['user.email'] = user.email
      end

      def default_options(options = {})
        {raise: true, timeout: true}.merge(options)
      end

      def handle_exception(exception)
        Gitlab::GitLogger.error(exception.message)
        false
      end
    end
  end
end
