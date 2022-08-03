# frozen_string_literal: true

module TimeTracking
  class TimelogCategoryPolicy < BasePolicy
    delegate { @subject.namespace }
  end
end
