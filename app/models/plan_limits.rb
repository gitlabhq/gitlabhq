# frozen_string_literal: true

class PlanLimits < ApplicationRecord
  belongs_to :plan

  def exceeded?(limit_name, object)
    return false unless enabled?(limit_name)

    if object.is_a?(Integer)
      object >= read_attribute(limit_name)
    else
      # object.count >= limit value is slower than checking
      # if a record exists at the limit value - 1 position.
      object.limit(1).offset(read_attribute(limit_name) - 1).exists?
    end
  end

  private

  def enabled?(limit_name)
    read_attribute(limit_name) > 0
  end
end
