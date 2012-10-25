module Gitlab
  module Satellite
    # GitLab file editor
    #
    # It gives you ability to make changes to files
    # & commit this changes from GitLab UI.
    class EditFileAction < Action
      attr_accessor :path, :ref

      def initialize(user, project, ref, path)
        super user, project
        @path = path
        @ref = ref
      end

      def update(content, commit_message, last_commit)
        return false unless can_edit?(last_commit)

        in_locked_and_timed_satellite do |repo|
          prepare_satellite!(repo)

          repo.git.sh "git checkout -b #{ref} origin/#{ref}"
          File.open(path, 'w'){|f| f.write(content)}
          repo.git.sh "git add ."
          repo.git.sh "git commit -am '#{commit_message}'"
          output = repo.git.sh "git push origin #{ref}"

          # everything worked
          true
        end
      rescue Grit::Git::CommandFailed => ex
        Gitlab::GitLogger.error(ex.message)
        false
      end

      protected

      def can_edit?(last_commit)
        current_last_commit = @project.last_commit_for(ref, path).sha
        last_commit == current_last_commit
      end
    end
  end
end
