module Gitlab
  module Checks
    class ForcePush
      def self.force_push?(project, oldrev, newrev, env: {})
        return false if project.empty_repo?

        # Created or deleted branch
        if Gitlab::Git.blank_ref?(oldrev) || Gitlab::Git.blank_ref?(newrev)
          false
        else
          missed_ref, exit_status = Gitlab::Git::RevList.new(oldrev, newrev, project: project, env: env).execute

          if exit_status == 0
            missed_ref.present?
          else
            raise "Got a non-zero exit code while calling out to `git rev-list` in the force-push check."
          end
        end
      end
    end
  end
end
