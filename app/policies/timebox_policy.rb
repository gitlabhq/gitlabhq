# frozen_string_literal: true

class TimeboxPolicy < BasePolicy
  # stub permissions policy on None, Any, Upcoming, Started and Current timeboxes

  rule { default }.policy do
    enable :read_iteration
    enable :read_milestone
  end
end
