# frozen_string_literal: true

module ContainerRegistry
  module Protection
    class TagRulePolicy < BasePolicy
      delegate { @subject.project }
    end
  end
end
