# frozen_string_literal: true

module StateEventable
  extend ActiveSupport::Concern

  included do
    has_many :resource_state_events
  end
end
