module Gitlab
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

      def clear_and_update!
        project.ensure_satellite_exists

        @repo = nil
        clear_working_dir!
        delete_heads!
        remove_remotes!
        update_from_source!
      end

      def create
        output, status = popen(%W(git clone -- #{project.repository.path_to_repo} #{path}),
                               Gitlab.config.satellites.path)

        log("PID: #{project.id}: git clone #{project.repository.path_to_repo} #{path}")
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
        project.ensure_satellite_exists

        File.open(lock_file, "w+") do |f|
          begin
            f.flock File::LOCK_EX
            yield
          ensure
            f.flock File::LOCK_UN
          end
        end
      end

      def lock_file
        create_locks_dir unless File.exists?(lock_files_dir)
        File.join(lock_files_dir, "satellite_#{project.id}.lock")
      end

      def path
        File.join(Gitlab.config.satellites.path, project.path_with_namespace)
      end

      def repo
        project.ensure_satellite_exists

        @repo ||= Grit::Repo.new(path)
      end

      def destroy
        FileUtils.rm_rf(path)
      end

      private

      # Clear the working directory
      def clear_working_dir!
        repo.git.reset(hard: true)
        repo.git.clean(f: true, d: true, x: true)
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
          repo.git.checkout(default_options({b: true}), PARKING_BRANCH)
        end

        # remove the parking branch from the list of heads ...
        heads.delete(PARKING_BRANCH)
        # ... and delete all others
        heads.each { |head| repo.git.branch(default_options({D: true}), head) }
      end

      # Deletes all remotes except origin
      #
      # This ensures we have no remote name clashes or issues updating branches when
      # working with the satellite.
      def remove_remotes!
        remotes = repo.git.remote.split(' ')
        remotes.delete('origin')
        remotes.each { |name| repo.git.remote(default_options,'rm', name)}
      end

      # Updates the satellite from bare repo
      #
      # Note: this will only update remote branches (i.e. origin/*)
      def update_from_source!
        repo.git.fetch(default_options, :origin)
      end

      def default_options(options = {})
        {raise: true, timeout: true}.merge(options)
      end

      # Create directory for storing
      # satellites lock files
      def create_locks_dir
        FileUtils.mkdir_p(lock_files_dir)
      end

      def lock_files_dir
        @lock_files_dir ||= File.join(Gitlab.config.satellites.path, "tmp")
      end
    end
  end
end
