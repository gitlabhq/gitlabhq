module Gitlab
  class SatelliteNotExistError < StandardError; end

  module Satellite
    class Satellite
      include Gitlab::Popen

      PARKING_BRANCH = "__parking_branch"

      attr_accessor :project

      def initialize(project)
        @project = project
      end

      def log message
        Gitlab::Satellite::Logger.error(message)
      end

      def raise_no_satellite
        raise SatelliteNotExistError.new("Satellite doesn't exist")
      end

      def clear_and_update!
        raise_no_satellite unless exists?

        delete_heads!
        clear_working_dir!
        update_from_source!
      end

      def create
        output, status = popen("git clone #{project.url_to_repo} #{path}",
                               Gitlab.config.satellites.path)

        log("PID: #{project.id}: git clone #{project.url_to_repo} #{path}")
        log("PID: #{project.id}: -> #{output}")

        if status.zero?
          true
        else
          log("Failed to create satellite for #{project.name_with_namespace}")
          false
        end
      end

      def exists?
        File.exists? path
      end

      # * Locks the satellite
      # * Changes the current directory to the satellite's working dir
      # * Yields
      def lock
        raise_no_satellite unless exists?

        File.open(lock_file, "w+") do |f|
          f.flock(File::LOCK_EX)

          Dir.chdir(path) do
            return yield
          end
        end
      end

      def lock_file
        Rails.root.join("tmp", "satellite_#{project.id}.lock")
      end

      def path
        File.join(Gitlab.config.satellites.path, project.path_with_namespace)
      end

      def repo
        raise_no_satellite unless exists?

        @repo ||= Grit::Repo.new(path)
      end

      def destroy
        FileUtils.rm_rf(path)
      end

      private

      # Clear the working directory
      def clear_working_dir!
        repo.git.reset(hard: true)
      end

      # Deletes all branches except the parking branch
      #
      # This ensures we have no name clashes or issues updating branches when
      # working with the satellite.
      def delete_heads!
        heads = repo.heads.map(&:name)

        # update or create the parking branch
        if heads.include? PARKING_BRANCH
          repo.git.checkout({}, PARKING_BRANCH)
        else
          repo.git.checkout({b: true}, PARKING_BRANCH)
        end

        # remove the parking branch from the list of heads ...
        heads.delete(PARKING_BRANCH)
        # ... and delete all others
        heads.each { |head| repo.git.branch({D: true}, head) }
      end

      # Updates the satellite from Gitolite
      #
      # Note: this will only update remote branches (i.e. origin/*)
      def update_from_source!
        repo.git.fetch({timeout: true}, :origin)
      end
    end
  end
end
