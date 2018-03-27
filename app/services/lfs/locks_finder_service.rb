module Lfs
  class LocksFinderService < BaseService
    def execute
      success(locks: find_locks)
    rescue => ex
      error(ex.message, 500)
    end

    private

    def find_locks
      options = params.slice(:id, :path).compact.symbolize_keys

      project.lfs_file_locks.where(options)
    end
  end
end
