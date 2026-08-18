# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Triggers
      ALL = [
        { id: 'deployment_requested', name: 'Deployment' }.freeze
      ].freeze
    end
  end
end
