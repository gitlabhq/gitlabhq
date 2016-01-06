module Gitlab
  class ForcePushCheck
    def self.force_push?(project, oldrev, newrev)
      return false if project.empty_repo?

      # Created or deleted branch
      if Gitlab::Git.blank_ref?(oldrev) || Gitlab::Git.blank_ref?(newrev)
        false
      else
        missed_refs, _ = Gitlab::Popen.popen(%W(#{Gitlab.config.git.bin_path} --git-dir=#{project.repository.path_to_repo} rev-list #{oldrev} ^#{newrev}))
        missed_refs.split("\n").size > 0
      end
    end
  end
end
