# frozen_string_literal: true

module MilestoneEventable
  extend ActiveSupport::Concern

  included do
    has_many :resource_milestone_events
  end
end
