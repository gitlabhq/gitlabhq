# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Triggers
      # Canonical trigger identifiers, mirroring the Govern model enums. ALL
      # below is the user-facing authoring catalog and may lag behind this
      # list: recorded evaluations can reference any of these types.
      TYPES = %w[deployment_requested environment_advanced deployment_promoted].freeze

      ALL = [
        { id: 'deployment_requested', name: 'Deployment' }.freeze
      ].freeze
    end
  end
end
