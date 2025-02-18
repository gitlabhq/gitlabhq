# frozen_string_literal: true

module Doorkeeper # rubocop:disable Gitlab/BoundedContexts -- Override from a gem
  module DeviceAuthorizationGrant
    class DeviceGrant < ApplicationRecord
      include Doorkeeper::DeviceAuthorizationGrant::DeviceGrantMixin
      include SafelyChangeColumnDefault

      columns_changing_default :organization_id

      belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    end
  end
end
