# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Actions
      BLOCK = 'block'
      REQUIRE_APPROVAL = 'require_approval'
      SET_SETTING = 'set_setting'
      # Observes only, so it runs in every enforcement mode.
      LOG_AUDIT_TRAIL = 'log_audit_trail'

      ALL = [
        { id: BLOCK, name: 'Block' }.freeze,
        { id: REQUIRE_APPROVAL, name: 'Require approval' }.freeze,
        { id: SET_SETTING, name: 'Set project setting' }.freeze,
        { id: LOG_AUDIT_TRAIL, name: 'Log audit trail' }.freeze
      ].freeze
    end
  end
end
