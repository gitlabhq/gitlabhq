module EE
  module Lfs
    module UnlockFileService
      def execute
        result = super

        if (result[:status] == :success) && project.feature_available?(:file_locks)
          if path_lock = project.path_locks.find_by(path: result[:lock].path)
            PathLocks::UnlockService.new(project, current_user).execute(path_lock)
          end
        end

        result
      end
    end
  end
end
