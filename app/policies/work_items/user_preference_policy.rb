# frozen_string_literal: true

module WorkItems
  class UserPreferencePolicy < BasePolicy
    delegate { @subject.namespace }
  end
end
