module Gitlab
  class ForcePushCheck
    def self.force_push?(project, oldrev, newrev)
      return false if project.empty_repo?

      if oldrev != Gitlab::Git::BLANK_SHA && newrev != Gitlab::Git::BLANK_SHA
        missed_refs = IO.popen(%W(git --git-dir=#{project.repository.path_to_repo} rev-list #{oldrev} ^#{newrev})).read
        missed_refs.split("\n").size > 0
      else
        false
      end
    end
  end
end

