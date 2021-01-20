# frozen_string_literal: true

class OnboardingProgressService
  def initialize(namespace)
    @namespace = namespace&.root_ancestor
  end

  def execute(action:)
    return unless @namespace

    OnboardingProgress.register(@namespace, action)
  end
end
