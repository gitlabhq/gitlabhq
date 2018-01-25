module Lfs
  class LockFileService < BaseService
    prepend EE::Lfs::LockFileService

    def execute
      if current_lock
        error('already created lock', 409, current_lock)
      else
        create_lock!
      end
    rescue => ex
      error(ex.message, 500)
    end

    private

    def current_lock
      @current_lock ||= project.lfs_file_locks.find_by(path: params[:path])
    end

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
