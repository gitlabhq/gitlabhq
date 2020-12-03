# frozen_string_literal: true

class OnboardingProgressService
  def initialize(namespace)
    @namespace = namespace
  end

  def execute(action:)
    NamespaceOnboardingAction.create_action(@namespace, action)
  end
end
