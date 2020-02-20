# frozen_string_literal: true

module Projects
  class DestroyRollbackService < BaseService
    include Gitlab::ShellAdapter

    def execute
      return unless project

      Projects::ForksCountService.new(project).delete_cache

      unless rollback_repository(project.repository)
        raise_error(s_('DeleteProject|Failed to restore project repository. Please contact the administrator.'))
      end

      unless rollback_repository(project.wiki.repository)
        raise_error(s_('DeleteProject|Failed to restore wiki repository. Please contact the administrator.'))
      end
    end

    private

    def rollback_repository(repository)
      return true unless repository

      result = Repositories::DestroyRollbackService.new(repository).execute

      result[:status] == :success
    end
  end
end
