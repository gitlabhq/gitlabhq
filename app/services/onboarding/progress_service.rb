# frozen_string_literal: true

module Onboarding
  class ProgressService
    def initialize(namespace)
      @namespace = namespace&.root_ancestor
    end

    def execute(action:)
      return unless @namespace

      Onboarding::Progress.register(@namespace, action)
    end
  end
end
