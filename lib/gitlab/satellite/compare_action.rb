module Gitlab
  module Satellite
    class BranchesWithoutParent < StandardError; end

    class CompareAction < Action
      def initialize(user, target_project, target_branch, source_project, source_branch)
        super user, target_project

        @target_project, @target_branch = target_project, target_branch
        @source_project, @source_branch = source_project, source_branch
      end

      # Compare 2 repositories and return Gitlab::CompareResult object
      def result
        in_locked_and_timed_satellite do |target_repo|
          prepare_satellite!(target_repo)
          update_satellite_source_and_target!(target_repo)

          Gitlab::CompareResult.new(compare(target_repo))
        end
      rescue Grit::Git::CommandFailed => ex
        raise BranchesWithoutParent
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
        @compare ||= Gitlab::Git::Compare.new(
          Gitlab::Git::Repository.new(repo.path),
          "origin/#{@target_branch}",
          "source/#{@source_branch}"
        )
      end
    end
  end
end
