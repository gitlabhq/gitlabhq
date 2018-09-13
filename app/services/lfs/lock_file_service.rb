# frozen_string_literal: true

module Lfs
  class LockFileService < BaseService
    prepend EE::Lfs::LockFileService

    def execute
      unless can?(current_user, :push_code, project)
        raise Gitlab::GitAccess::UnauthorizedError, 'You have no permissions'
      end

      create_lock!
    rescue ActiveRecord::RecordNotUnique
      error('already locked', 409, current_lock)
    rescue Gitlab::GitAccess::UnauthorizedError => ex
      error(ex.message, 403)
    rescue => ex
      error(ex.message, 500)
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def current_lock
      project.lfs_file_locks.find_by(path: params[:path])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_lock!
      lock = project.lfs_file_locks.create!(user: current_user,
                                            path: params[:path])

      success(http_status: 201, lock: lock)
    end

    def error(message, http_status, lock = nil)
      {
        status: :error,
        message: message,
        http_status: http_status,
        lock: lock
      }
    end
  end
end
