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

    belongs_to :updated_state_by, class_name: 'User', foreign_key: :updated_state_by_user_id

    after_initialize :set_state, unless: :persisted?

    def attention_requested_by
      return unless attention_requested?

      updated_state_by
    end
  end
end
