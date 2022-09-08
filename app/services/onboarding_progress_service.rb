# frozen_string_literal: true

class OnboardingProgressService
  class Async
    attr_reader :namespace_id

    def initialize(namespace_id)
      @namespace_id = namespace_id
    end

    def execute(action:)
      return unless Onboarding::Progress.not_completed?(namespace_id, action)

      Namespaces::OnboardingProgressWorker.perform_async(namespace_id, action)
    end
  end

  def self.async(namespace_id)
    Async.new(namespace_id)
  end

  def initialize(namespace)
    @namespace = namespace&.root_ancestor
  end

  def execute(action:)
    return unless @namespace

    Onboarding::Progress.register(@namespace, action)
  end
end
