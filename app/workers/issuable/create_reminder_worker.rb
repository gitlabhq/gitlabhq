# frozen_string_literal: true

module Issuable
  class CreateReminderWorker
    include ApplicationWorker

    data_consistency :delayed

    idempotent!
    feature_category :code_review_workflow

    def perform(target_id, target_type, user_id)
      # Create a notification for the user against the target
      #
      current_user = User.find(user_id)
      return unless current_user

      target = target_type.constantize.find(target_id)
      return unless target

      TodoService.new.mark_todo(target, current_user)
    end
  end
end
