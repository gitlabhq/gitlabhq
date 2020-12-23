# frozen_string_literal: true

class OnboardingProgressService
  def initialize(namespace)
    @namespace = namespace&.root_ancestor
  end

  def execute(action:)
    return unless @namespace

    NamespaceOnboardingAction.create_action(@namespace, action)
  end
end
