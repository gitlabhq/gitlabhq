# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Rules
      ALL = [
        { id: 'custom', name: 'Custom' }.freeze,
        { id: 'calendar', name: 'Calendar' }.freeze,
        { id: 'environment', name: 'Environment' }.freeze
      ].freeze
    end
  end
end
