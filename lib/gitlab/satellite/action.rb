module Gitlab
  module Satellite
    class Action
      DEFAULT_OPTIONS = { git_timeout: 30.seconds }

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
        Grit::Git.with_timeout(options[:git_timeout]) do
          File.open(lock_file, "w+") do |f|
            f.flock(File::LOCK_EX)

            unless project.satellite.exists?
              raise "Satellite doesn't exist"
            end

            Dir.chdir(project.satellite.path) do
              repo = Grit::Repo.new('.')

              return yield repo
            end
          end
        end
      rescue Errno::ENOMEM => ex
        Gitlab::GitLogger.error(ex.message)
        return false
      rescue Grit::Git::GitTimeout => ex
        Gitlab::GitLogger.error(ex.message)
        return false
      end

      def lock_file
        Rails.root.join("tmp", "#{project.path}.lock")
      end

      # * Clears the satellite
      # * Updates the satellite from Gitolite
      # * Sets up Git variables for the user
      #
      # Note: use this within #in_locked_and_timed_satellite
      def prepare_satellite!(repo)
        project.satellite.clear

        repo.git.reset(hard: true)
        repo.git.fetch({}, :origin)

        repo.git.config({}, "user.name", user.name)
        repo.git.config({}, "user.email", user.email)
      end
    end
  end
end
