# frozen_string_literal: true

# Original file https://github.com/doorkeeper-gem/doorkeeper/blob/main/lib/doorkeeper/orm/active_record/access_token.rb

module Doorkeeper # rubocop:disable Gitlab/BoundedContexts -- Override from a gem
  class AccessToken < ::ApplicationRecord
    include Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken
    include SafelyChangeColumnDefault
    # Some callers create and look tokens up through this class rather than
    # OauthAccessToken, so the sticking lives here and the subclass inherits it.
    include Doorkeeper::Concerns::LoadBalancerSticking

    columns_changing_default :organization_id

    belongs_to :organization, class_name: 'Organizations::Organization', optional: false
    belongs_to :resource_owner, class_name: 'User'

    def self.sticking_namespace
      :oauth_token
    end

    private

    def plaintext_secrets_to_stick
      [plaintext_token, plaintext_refresh_token].compact_blank
    end
  end
end
