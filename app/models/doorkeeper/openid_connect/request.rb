# frozen_string_literal: true

module Doorkeeper # rubocop:disable Gitlab/BoundedContexts -- Override from a gem
  module OpenidConnect
    class Request < ApplicationRecord
      self.table_name = :"#{table_name_prefix}oauth_openid_requests#{table_name_suffix}"
      include SafelyChangeColumnDefault

      columns_changing_default :organization_id

      validates :access_grant_id, :nonce, presence: true
      belongs_to :access_grant,
        class_name: 'Doorkeeper::AccessGrant',
        inverse_of: :openid_request

      belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    end
  end
end
