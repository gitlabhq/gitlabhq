module Gitlab
  module Satellite
    class Satellite
      PARKING_BRANCH = "__parking_branch"

      attr_accessor :project

      def initialize(project)
        @project = project
      end

      def clear_and_update!
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

      def path
        Rails.root.join("tmp", "repo_satellites", project.path)
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
        heads = repo.heads.map{|head| head.name}

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

      def repo
        @repo ||= Grit::Repo.new(path)
      end

      # Updates the satellite from Gitolite
      #
      # Note: this will only update remote branches (i.e. origin/*)
      def update_from_source!
        repo.git.fetch({}, :origin)
      end
    end
  end
end
