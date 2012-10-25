module Gitlab
  module Satellite
    # GitLab file editor
    #
    # It gives you ability to make changes to files
    # & commit this changes from GitLab UI.
    class EditFileAction < Action
      attr_accessor :file_path, :ref

      def initialize(user, project, ref, file_path)
        super user, project, git_timeout: 10.seconds
        @file_path = file_path
        @ref = ref
      end

      def commit!(content, commit_message, last_commit)
        return false unless can_edit?(last_commit)

        in_locked_and_timed_satellite do |repo|
          prepare_satellite!(repo)

          # create target branch in satellite at the corresponding commit from Gitolite
          repo.git.checkout({raise: true, timeout: true, b: true}, ref, "origin/#{ref}")

          # update the file in the satellite's working dir
          file_path_in_satellite = File.join(repo.working_dir, file_path)
          File.open(file_path_in_satellite, 'w') { |f| f.write(content) }

          # commit the changes
          # will raise CommandFailed when commit fails
          repo.git.commit(raise: true, timeout: true, a: true, m: commit_message)


          # push commit back to Gitolite
          # will raise CommandFailed when push fails
          repo.git.push({raise: true, timeout: true}, :origin, ref)

          # everything worked
          true
        end
      rescue Grit::Git::CommandFailed => ex
        Gitlab::GitLogger.error(ex.message)
        false
      end

      protected

      def can_edit?(last_commit)
        current_last_commit = @project.last_commit_for(ref, file_path).sha
        last_commit == current_last_commit
      end
    end
  end
end
