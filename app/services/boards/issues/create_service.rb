module Boards
  module Issues
    class CreateService < Boards::BaseService
      def execute(list)
        params.merge!(label_ids: [list.label_id])
        create_issue
      end

      private

      def create_issue
        ::Issues::CreateService.new(project, current_user, params).execute
      end
    end
  end
end
