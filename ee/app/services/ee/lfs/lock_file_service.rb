module EE
  module Lfs
    module LockFileService
      def execute
        result = super

        if (result[:status] == :success) &&
            create_path_lock? &&
            project.feature_available?(:file_locks)
          PathLocks::LockService.new(project, current_user).execute(result[:lock].path)
        end

        result
      end

      private

      def create_path_lock?
        params[:create_path_lock] != false
      end
    end
  end
end
