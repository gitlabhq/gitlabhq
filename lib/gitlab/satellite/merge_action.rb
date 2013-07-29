module Gitlab
  module Satellite
    # GitLab server-side merge
    class MergeAction < Action
      attr_accessor :merge_request

      def initialize(user, merge_request)
        super user, merge_request.project
        @merge_request = merge_request
      end

      # Checks if a merge request can be executed without user interaction
      def can_be_merged?
        in_locked_and_timed_satellite do |merge_repo|
          merge_in_satellite!(merge_repo)
        end
      end

      # Merges the source branch into the target branch in the satellite and
      # pushes it back to Gitolite.
      # It also removes the source branch if requested in the merge request.
      #
      # Returns false if the merge produced conflicts
      # Returns false if pushing from the satellite to Gitolite failed or was rejected
      # Returns true otherwise
      def merge!
        in_locked_and_timed_satellite do |merge_repo|
          if merge_in_satellite!(merge_repo)
            # push merge back to Gitolite
            # will raise CommandFailed when push fails
            merge_repo.git.push({raise: true, timeout: true}, :origin, merge_request.target_branch)

            # remove source branch
            if merge_request.should_remove_source_branch && !project.root_ref?(merge_request.source_branch)
              # will raise CommandFailed when push fails
              merge_repo.git.push({raise: true, timeout: true}, :origin, ":#{merge_request.source_branch}")
            end

            # merge, push and branch removal successful
            true
          end
        end
      rescue Grit::Git::CommandFailed => ex
        Gitlab::GitLogger.error(ex.message)
        false
      end

      private

      # Merges the source_branch into the target_branch in the satellite.
      #
      # Note: it will clear out the satellite before doing anything
      #
      # Returns false if the merge produced conflicts
      # Returns true otherwise
      def merge_in_satellite!(repo)
        prepare_satellite!(repo)

        # create target branch in satellite at the corresponding commit from Git
        repo.git.update_ref({raise: true, timeout: true},
                            "refs/heads/#{merge_request.target_branch}",
                            "origin/#{merge_request.target_branch}")
        # switch to the target branch
        repo.git.symbolic_ref({raise: true, timeout: true},
                              "HEAD", "refs/heads/#{merge_request.target_branch}")
        # make the worktree match the git commit
        repo.git.reset({raise: true, timeout: true, hard: true},
                       "origin/#{merge_request.target_branch}", "--")
        # cleanup cruft that may have been left behind
        repo.git.clean({raise: true, timeout: true, force: true, x:true, d:true})

        # merge the source branch from Git into the satellite
        # will raise CommandFailed when merge fails
        repo.git.pull({raise: true, timeout: true, no_ff: true}, :origin, merge_request.source_branch)
      rescue Grit::Git::CommandFailed => ex
        Gitlab::GitLogger.error(ex.message)
        false
      end
    end
  end
end
