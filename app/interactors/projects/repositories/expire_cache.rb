module Projects::Repositories
  class ExpireCache < Projects::Base
    def perform
      project = context[:project]

      unless project.empty_repo?
        project.repository.expire_cache
      end
    end

    def rollback
      # Can we do something?
    end
  end
end
