module Gitlab
  module Checks
    class ForcePush
      def self.force_push?(project, oldrev, newrev, env: {})
        return false if project.empty_repo?

        # Created or deleted branch
        if Gitlab::Git.blank_ref?(oldrev) || Gitlab::Git.blank_ref?(newrev)
          false
        else
          missed_ref, _ = Gitlab::Git::RevList.new(oldrev, newrev, project: project, env: env).execute
          missed_ref.present?
        end
      end
    end
  end
end
