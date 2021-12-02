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
  end
end
