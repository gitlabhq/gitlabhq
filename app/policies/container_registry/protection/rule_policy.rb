# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class RulePolicy < BasePolicy
      delegate { @subject.project }
    end
  end
end
