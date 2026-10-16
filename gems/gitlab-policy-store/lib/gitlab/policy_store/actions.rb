# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Actions
      BLOCK = 'block'
      REQUIRE_APPROVAL = 'require_approval'
      SET_SETTING = 'set_setting'

      ALL = [
        { id: BLOCK, name: 'Block' }.freeze,
        { id: REQUIRE_APPROVAL, name: 'Require approval' }.freeze,
        { id: SET_SETTING, name: 'Set project setting' }.freeze
      ].freeze
    end
  end
end
