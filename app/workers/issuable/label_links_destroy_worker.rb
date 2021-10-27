# frozen_string_literal: true

module Issuable
  class LabelLinksDestroyWorker
    include ApplicationWorker

    data_consistency :always

    idempotent!
    feature_category :team_planning

    def perform(target_id, target_type)
      ::Issuable::DestroyLabelLinksService.new(target_id, target_type).execute
    end
  end
end
