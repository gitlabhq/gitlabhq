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
          common_commit = target_repo.git.native(:merge_base, default_options, ["origin/#{@target_branch}", "source/#{@source_branch}"]).strip
          #this method doesn't take default options
          diffs = target_repo.diff(common_commit, "source/#{@source_branch}")
          diffs = diffs.map { |diff| Gitlab::Git::Diff.new(diff) }
          diffs
        end
      rescue Grit::Git::CommandFailed => ex
        raise BranchesWithoutParent
      end

      # Retrieve an array of commits between the source and the target
      def commits
        in_locked_and_timed_satellite do |target_repo|
          prepare_satellite!(target_repo)
          update_satellite_source_and_target!(target_repo)
          commits = target_repo.commits_between("origin/#{@target_branch}", "source/#{@source_branch}")
          commits = commits.map { |commit| Gitlab::Git::Commit.new(commit, nil) }
          commits
        end
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

      private

      # Assumes a satellite exists that is a fresh clone of the projects repo, prepares satellite for diffs
      def update_satellite_source_and_target!(target_repo)
        target_repo.remote_add('source', @source_project.repository.path_to_repo)
        target_repo.remote_fetch('source')
        target_repo.git.checkout(default_options({b: true}), @target_branch, "origin/#{@target_branch}")
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end
    end
  end
end
