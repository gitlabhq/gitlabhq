# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Actions
      ALL = [
        { id: 'block', name: 'Block' }.freeze,
        { id: 'require_approval', name: 'Require approval' }.freeze
      ].freeze
    end
  end
end
