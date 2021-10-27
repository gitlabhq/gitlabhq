# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class MergeRequestStageEvent < ApplicationRecord
      include StageEventModel
      extend SuppressCompositePrimaryKeyWarning

      validates(*%i[stage_event_hash_id merge_request_id group_id project_id start_event_timestamp], presence: true)

      alias_attribute :state, :state_id
      enum state: MergeRequest.available_states, _suffix: true

      def self.issuable_id_column
        :merge_request_id
      end
    end
  end
end
