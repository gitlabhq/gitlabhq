module EE
  module Lfs
    module LockFileService
      def execute
        result = super

        if (result[:status] == :success) && project.feature_available?(:file_locks)
          PathLocks::LockService.new(project, current_user).execute(result[:lock].path)
        end

        result
      end
    end
  end
end
