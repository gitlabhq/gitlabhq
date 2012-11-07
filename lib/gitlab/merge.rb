module Gitlab
  class Merge
    attr_accessor :merge_request, :project, :user

    def initialize(merge_request, user)
      @merge_request = merge_request
      @project = merge_request.project
      @user = user
    end

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
    # Returns false if pushing from the satallite to Gitolite failed or was rejected
    # Returns true otherwise
    def merge!
      in_locked_and_timed_satellite do |merge_repo|
        if merge_in_satellite!(merge_repo)
          # push merge back to Gitolite
          # will raise CommandFailed when push fails
          merge_repo.git.push({raise: true}, :origin, merge_request.target_branch)

          # remove source branch
          if merge_request.should_remove_source_branch && !project.root_ref?(merge_request.source_branch)
            # will raise CommandFailed when push fails
            merge_repo.git.push({raise: true}, :origin, ":#{merge_request.source_branch}")
          end

          # merge, push and branch removal successful
          true
        end
      end
    rescue Grit::Git::CommandFailed
      false
    end

    private

    # * Sets a 30s timeout for Git
    # * Locks the satellite repo
    # * Yields the prepared satallite repo
    def in_locked_and_timed_satellite
      Grit::Git.with_timeout(30.seconds) do
        lock_file = Rails.root.join("tmp", "#{project.path}.lock")

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
    rescue Grit::Git::GitTimeout
      return false
    end

    # Merges the source_branch into the target_branch in the satellite.
    #
    # Note: it will clear out the satellite before doing anything
    #
    # Returns false if the merge produced conflicts
    # Returns true otherwise
    def merge_in_satellite!(repo)
      prepare_satelite!(repo)

      # create target branch in satellite at the corresponding commit from Gitolite
      repo.git.checkout({b: true}, merge_request.target_branch, "origin/#{merge_request.target_branch}")

      # merge the source branch from Gitolite into the satellite
      # will raise CommandFailed when merge fails
      repo.git.pull({no_ff: true, raise: true}, :origin, merge_request.source_branch)
    rescue Grit::Git::CommandFailed
      false
    end

    # * Clears the satellite
    # * Updates the satellite from Gitolite
    # * Sets up Git variables for the user
    def prepare_satelite!(repo)
      project.satellite.clear

      repo.git.reset(hard: true)
      repo.git.fetch({}, :origin)

      repo.git.config({}, "user.name", user.name)
      repo.git.config({}, "user.email", user.email)
    end
  end
end
