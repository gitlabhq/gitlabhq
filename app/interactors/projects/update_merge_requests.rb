module Projects
  class UpdateMergeRequests < Projects::Base
    def perform
      project = context[:project]
      oldrev = context[:oldrev]
      newrev = context[:newrev]
      ref = context[:ref]
      user = context[:user]

      project.update_merge_requests(oldrev, newrev, ref, user)
    end

    def rollback

    end
  end
end
