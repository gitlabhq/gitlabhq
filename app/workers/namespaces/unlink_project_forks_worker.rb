# frozen_string_literal: true

module Namespaces
  class UnlinkProjectForksWorker
    include ApplicationWorker

    data_consistency :sticky

    queue_namespace :namespaces
    feature_category :source_code_management
    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once

    def perform(group_id, user_id)
      group = Group.find_by_id(group_id)
      user = User.find_by_id(user_id)

      return unless group && user

      Namespaces::UnlinkProjectForksService.new(group, user).execute
    end
  end
end
