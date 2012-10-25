module Gitlab
  module Satellite
    class Action
      DEFAULT_OPTIONS = { git_timeout: 30.seconds }

      attr_accessor :options, :project

      def initialize(project, options = {})
        @project = project
        @options = DEFAULT_OPTIONS.merge(options)
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
    end
  end
end
