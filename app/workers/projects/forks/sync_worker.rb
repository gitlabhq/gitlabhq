# frozen_string_literal: true

module Projects
  module Forks
    class SyncWorker
      include ApplicationWorker

      data_consistency :sticky
      idempotent!
      urgency :high
      feature_category :source_code_management

      def perform(project_id, user_id, ref)
        project = Project.find_by_id(project_id)
        user = User.find_by_id(user_id)
        return unless project && user

        ::Projects::Forks::SyncService.new(project, user, ref).execute
      end
    end
  end
end
