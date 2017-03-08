module PathLocks
  class LockService < BaseService
    AccessDenied = Class.new(StandardError)

    include PathLocksHelper

    def execute(path)
      raise AccessDenied, 'You have no permissions' unless can?(current_user, :push_code, project)

      project.path_locks.create(path: path, user: current_user)
    end
  end
end
