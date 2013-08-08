module Gitlab
  module Satellite
    # GitLab server-side merge
    class MergeAction < Action
      attr_accessor :merge_request

      def initialize(user, merge_request)
        super user, merge_request.target_project
        @merge_request = merge_request
      end

      # Checks if a merge request can be executed without user interaction
      def can_be_merged?
        in_locked_and_timed_satellite do |merge_repo|
          prepare_satellite!(merge_repo)
          merge_in_satellite!(merge_repo)
        end
      end

      # Merges the source branch into the target branch in the satellite and
      # pushes it back to the repository.
      # It also removes the source branch if requested in the merge request (and this is permitted by the merge request).
      #
      # Returns false if the merge produced conflicts
      # Returns false if pushing from the satellite to the repository failed or was rejected
      # Returns true otherwise
      def merge!
        in_locked_and_timed_satellite do |merge_repo|
          prepare_satellite!(merge_repo)
          if merge_in_satellite!(merge_repo)
            # push merge back to Gitolite
            # will raise CommandFailed when push fails
            merge_repo.git.push(default_options, :origin, merge_request.target_branch)
            # remove source branch
            if merge_request.should_remove_source_branch && !project.root_ref?(merge_request.source_branch)
              # will raise CommandFailed when push fails
              merge_repo.git.push(default_options, :origin, ":#{merge_request.source_branch}")
            end
            # merge, push and branch removal successful
            true
          end
        end
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

      # Get a raw diff of the source to the target
      def diff_in_satellite
        in_locked_and_timed_satellite do |merge_repo|
          prepare_satellite!(merge_repo)
          update_satellite_source_and_target!(merge_repo)

          if merge_request.for_fork?
            diff = merge_repo.git.native(:diff, default_options, "origin/#{merge_request.target_branch}", "source/#{merge_request.source_branch}")
          else
            diff = merge_repo.git.native(:diff, default_options, "#{merge_request.target_branch}", "#{merge_request.source_branch}")
          end

          return diff
        end
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

      # Only show what is new in the source branch compared to the target branch, not the other way around.
      # The line below with merge_base is equivalent to diff with three dots (git diff branch1...branch2)
      # From the git documentation: "git diff A...B" is equivalent to "git diff $(git-merge-base A B) B"
      def diffs_between_satellite
        in_locked_and_timed_satellite do |merge_repo|
          prepare_satellite!(merge_repo)
          update_satellite_source_and_target!(merge_repo)
          if merge_request.for_fork?
            common_commit = merge_repo.git.native(:merge_base, default_options, ["origin/#{merge_request.target_branch}", "source/#{merge_request.source_branch}"]).strip
            #this method doesn't take default options
            diffs = merge_repo.diff(common_commit, "source/#{merge_request.source_branch}")
          else
            raise "Attempt to determine diffs between for a non forked merge request in satellite MergeRequest.id:[#{merge_request.id}]"
          end
          diffs = diffs.map { |diff| Gitlab::Git::Diff.new(diff) }
          return diffs
        end
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

      # Get commit as an email patch
      def format_patch
        in_locked_and_timed_satellite do |merge_repo|
          prepare_satellite!(merge_repo)
          update_satellite_source_and_target!(merge_repo)

          if (merge_request.for_fork?)
            patch = merge_repo.git.format_patch(default_options({stdout: true}), "origin/#{merge_request.target_branch}..source/#{merge_request.source_branch}")
          else
            patch = merge_repo.git.format_patch(default_options({stdout: true}), "#{merge_request.target_branch}..#{merge_request.source_branch}")
          end

          return patch
        end
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

      # Retrieve an array of commits between the source and the target
      def commits_between
        in_locked_and_timed_satellite do |merge_repo|
          prepare_satellite!(merge_repo)
          update_satellite_source_and_target!(merge_repo)
          if (merge_request.for_fork?)
            commits = merge_repo.commits_between("origin/#{merge_request.target_branch}", "source/#{merge_request.source_branch}")
          else
            raise "Attempt to determine commits between for a non forked merge request in satellite MergeRequest.id:[#{merge_request.id}]"
          end
          commits = commits.map { |commit| Gitlab::Git::Commit.new(commit, nil) }
          return commits
        end
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

      private
      # Merges the source_branch into the target_branch in the satellite.
      #
      # Note: it will clear out the satellite before doing anything
      #
      # Returns false if the merge produced conflicts
      # Returns true otherwise
      def merge_in_satellite!(repo)
        update_satellite_source_and_target!(repo)

        # merge the source branch into the satellite
        # will raise CommandFailed when merge fails
        if merge_request.for_fork?
          repo.git.pull(default_options({no_ff: true}), 'source', merge_request.source_branch)
        else
          repo.git.pull(default_options({no_ff: true}), 'origin', merge_request.source_branch)
        end
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

      # Assumes a satellite exists that is a fresh clone of the projects repo, prepares satellite for merges, diffs etc
      def update_satellite_source_and_target!(repo)
        if merge_request.for_fork?
          repo.remote_add('source', merge_request.source_project.repository.path_to_repo)
          repo.remote_fetch('source')
          repo.git.checkout(default_options({b: true}), merge_request.target_branch, "origin/#{merge_request.target_branch}")
        else
          # We can't trust the input here being branch names, we can't always check it out because it could be a relative ref i.e. HEAD~3
          # we could actually remove the if true, because it should never ever happen (as long as the satellite has been prepared)
          repo.git.checkout(default_options, "#{merge_request.source_branch}")
          repo.git.checkout(default_options, "#{merge_request.target_branch}")
        end
      rescue Grit::Git::CommandFailed => ex
        handle_exception(ex)
      end

    end
  end
end
