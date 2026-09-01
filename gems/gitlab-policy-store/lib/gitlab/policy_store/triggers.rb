# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Triggers
      # ALL is the user-facing authoring catalogue. TYPES mirrors the Govern
      # model enum; the evaluation recorder validates recorded evaluations
      # against it.
      TYPES = %w[deployment_requested environment_advanced deployment_promoted].freeze

      ALL = [
        { id: 'deployment_requested', name: 'Deployment requested' }.freeze,
        { id: 'environment_advanced', name: 'Environment advanced' }.freeze,
        { id: 'deployment_promoted', name: 'Deployment promoted' }.freeze
      ].freeze
    end
  end
end
