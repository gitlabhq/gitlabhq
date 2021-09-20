# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class IssueStageEvent < ApplicationRecord
      extend SuppressCompositePrimaryKeyWarning

      validates(*%i[stage_event_hash_id issue_id group_id project_id start_event_timestamp], presence: true)
    end
  end
end
