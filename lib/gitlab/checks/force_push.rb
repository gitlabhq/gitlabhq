module Gitlab
  module Checks
    class ForcePush
      def self.force_push?(project, oldrev, newrev)
        return false if project.empty_repo?

        # Created or deleted branch
        if Gitlab::Git.blank_ref?(oldrev) || Gitlab::Git.blank_ref?(newrev)
          false
        else
          missed_ref, _ = Gitlab::Popen.popen(%W[#{Gitlab.config.git.bin_path} --git-dir=#{project.repository.path_to_repo} rev-list --max-count=1 #{oldrev} ^#{newrev}])
          missed_ref.present?
        end
      end
    end
  end
end
