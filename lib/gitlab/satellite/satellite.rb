module Gitlab
  module Satellite
    class Satellite
      PARKING_BRANCH = "__parking_branch"

      attr_accessor :project

      def initialize(project)
        @project = project
      end

      def clear_and_update!
        raise "Satellite doesn't exist" unless exists?

        delete_heads!
        clear_working_dir!
        update_from_source!
      end

      def create
        `git clone #{project.url_to_repo} #{path}`
      end

      def exists?
        File.exists? path
      end

      # * Locks the satellite
      # * Changes the current directory to the satellite's working dir
      # * Yields
      def lock
        raise "Satellite doesn't exist" unless exists?

        File.open(lock_file, "w+") do |f|
          f.flock(File::LOCK_EX)

          Dir.chdir(path) do
            return yield
          end
        end
      end

      def lock_file
        Rails.root.join("tmp", "#{project.path}.lock")
      end

      def path
        Rails.root.join("tmp", "repo_satellites", project.path)
      end

      def repo
        raise "Satellite doesn't exist" unless exists?

        @repo ||= Grit::Repo.new(path)
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
