module Gitlab
  module Checks
    class ForcePush
      def self.force_push?(project, oldrev, newrev)
        return false if project.empty_repo?

        # Created or deleted branch
        if Gitlab::Git.blank_ref?(oldrev) || Gitlab::Git.blank_ref?(newrev)
          false
        else
          Gitlab::Git::RevList.new(
            path_to_repo: project.repository.path_to_repo,
            oldrev: oldrev, newrev: newrev).missed_ref.present?
        end
      end
    end
  end
end
