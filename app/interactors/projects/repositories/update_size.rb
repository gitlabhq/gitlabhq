module Projects::Repositories
  class UpdateSize < Projects::Base
    def perform
      project = context[:project]

      context[:old_repository_size] = project.repository_size
      project.update_repository_size
    end

    def rollback
      project.update_attribute(:repository_size, context[:old_repository_size])
      context.delete(:old_repository_size)
    end
  end
end
