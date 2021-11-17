# frozen_string_literal: true

module MergeRequestReviewerState
  extend ActiveSupport::Concern

  included do
    enum state: {
      unreviewed: 0,
      reviewed: 1,
      attention_requested: 2
    }

    validates :state,
      presence: true,
      inclusion: { in: self.states.keys }

    after_initialize :set_state, unless: :persisted?

    def set_state
      if Feature.enabled?(:mr_attention_requests, self.merge_request&.project, default_enabled: :yaml)
        self.state = :attention_requested
      end
    end
  end
end
