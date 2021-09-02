# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class MergeRequestStageEvent < ApplicationRecord
      extend SuppressCompositePrimaryKeyWarning

      validates(*%i[stage_event_hash_id merge_request_id group_id project_id start_event_timestamp], presence: true)
    end
  end
end
