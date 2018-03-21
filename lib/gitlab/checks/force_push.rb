module Gitlab
  module Checks
    class ForcePush
      def self.force_push?(project, oldrev, newrev)
        return false if project.empty_repo?

        # Created or deleted branch
        return false if Gitlab::Git.blank_ref?(oldrev) || Gitlab::Git.blank_ref?(newrev)

        GitalyClient.migrate(:force_push) do |is_enabled|
          if is_enabled
            !project
              .repository
              .gitaly_commit_client
              .ancestor?(oldrev, newrev)
          else
            Gitlab::Git::RevList.new(
              project.repository.raw, oldrev: oldrev, newrev: newrev
            ).missed_ref.present?
          end
        end
      end
    end
  end
end
