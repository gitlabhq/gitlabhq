# frozen_string_literal: true

module Clusters
  module Agents
    class ActivityEvent < ApplicationRecord
      include EachBatch
      include NullifyIfBlank

      self.table_name = 'agent_activity_events'

      belongs_to :agent, class_name: 'Clusters::Agent', optional: false
      belongs_to :user
      belongs_to :agent_token, class_name: 'Clusters::AgentToken'

      scope :in_timeline_order, -> { order(recorded_at: :desc, id: :desc) }
      scope :recorded_before, ->(cutoff) { where('recorded_at < ?', cutoff) }

      validates :recorded_at, :kind, :level, presence: true

      nullify_if_blank :detail

      enum kind: {
        token_created: 0,
        token_revoked: 1,
        agent_connected: 2,
        agent_disconnected: 3
      }, _prefix: true

      enum level: {
        debug: 0,
        info: 1,
        warn: 2,
        error: 3,
        fatal: 4,
        unknown: 5
      }, _prefix: true
    end
  end
end
