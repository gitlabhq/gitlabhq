# frozen_string_literal: true

module Doorkeeper # rubocop:disable Gitlab/BoundedContexts -- Override from a gem
  class AccessGrant < ApplicationRecord
    include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant
    include SafelyChangeColumnDefault
    # Doorkeeper creates and looks authorization codes up through this class, not
    # through OauthAccessGrant, so the sticking has to live here to cover them.
    include Doorkeeper::Concerns::LoadBalancerSticking

    columns_changing_default :organization_id

    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    has_one :openid_request,
      class_name: 'Doorkeeper::OpenidConnect::Request',
      inverse_of: :access_grant

    def self.sticking_namespace
      :oauth_grant
    end

    private

    def plaintext_secrets_to_stick
      [plaintext_token].compact_blank
    end
  end
end
