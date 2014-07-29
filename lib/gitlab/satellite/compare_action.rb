module Gitlab
  module Satellite
    class BranchesWithoutParent < StandardError; end

    class CompareAction < Action
      def initialize(user, target_project, target_branch, source_project, source_branch)
        super user, target_project

        @target_project, @target_branch = target_project, target_branch
        @source_project, @source_branch = source_project, source_branch
      end

      # Only show what is new in the source branch compared to the target branch, not the other way around.
      # The line below with merge_base is equivalent to diff with three dots (git diff branch1...branch2)
      # From the git documentation: "git diff A...B" is equivalent to "git diff $(git-merge-base A B) B"
      def diffs
        in_locked_and_timed_satellite do |target_repo|
          prepare_satellite!(target_repo)
          update_satellite_source_and_target!(target_repo)
          compare(target_repo).diffs
        end
      rescue Grit::Git::CommandFailed => ex
        raise BranchesWithoutParent
      end

      # Retrieve an array of commits between the source and the target
      def commits
        in_locked_and_timed_satellite do |target_repo|
          prepare_satellite!(target_repo)
          update_satellite_source_and_target!(target_repo)
          compare(target_repo).commits
        end
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

      private

      # Assumes a satellite exists that is a fresh clone of the projects repo, prepares satellite for diffs
      def update_satellite_source_and_target!(target_repo)
        target_repo.remote_add('source', @source_project.repository.path_to_repo)
        target_repo.remote_fetch('source')
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

      def compare(repo)
        @compare ||= Gitlab::Git::Compare.new(Gitlab::Git::Repository.new(repo.path), "origin/#{@target_branch}", "source/#{@source_branch}", 10000)
      end
    end
  end
end
