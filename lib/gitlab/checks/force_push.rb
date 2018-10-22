# frozen_string_literal: true

module Gitlab
  module Checks
    class ForcePush
      def self.force_push?(project, oldrev, newrev)
        return false if project.empty_repo?

        # Created or deleted branch
        return false if Gitlab::Git.blank_ref?(oldrev) || Gitlab::Git.blank_ref?(newrev)

        !project
          .repository
          .gitaly_commit_client
          .ancestor?(oldrev, newrev)
      end
    end
  end
end
