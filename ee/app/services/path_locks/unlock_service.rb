module PathLocks
  class UnlockService < BaseService
    AccessDenied = Class.new(StandardError)

    include PathLocksHelper

    def execute(path_lock)
      raise AccessDenied, _('You have no permissions') unless can_unlock?(path_lock)

      path_lock.destroy
    end
  end
end
