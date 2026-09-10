# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Actions
      BLOCK = 'block'
      REQUIRE_APPROVAL = 'require_approval'

      ALL = [
        { id: BLOCK, name: 'Block' }.freeze,
        { id: REQUIRE_APPROVAL, name: 'Require approval' }.freeze
      ].freeze
    end
  end
end
