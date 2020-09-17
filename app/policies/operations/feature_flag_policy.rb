# frozen_string_literal: true

module Operations
  class FeatureFlagPolicy < BasePolicy
    delegate { @subject.project }
  end
end
