# frozen_string_literal: true

module Authn
  module IamService
    # Duplicates the "Included in ID Token" claims from
    # config/initializers/doorkeeper_openid_connect.rb rather than reusing
    # Doorkeeper::OpenidConnect's claims DSL: that DSL expects an access
    # token responding to #application and a Doorkeeper::OAuth::Scopes-like
    # #scopes (#exists?), neither of which Authn::Tokens::IamOauthToken has
    # or is designed to have. Keep both claim sets in sync -- drift is
    # caught by spec/services/authn/iam_service/userinfo_claims_builder_parity_spec.rb.
    class UserinfoClaimsBuilder
      def initialize(user)
        @user = user
      end

      def claims
        raw_claims = {
          sub: user.id.to_s,
          auth_time: user.current_sign_in_at&.to_i,
          name: user.name,
          nickname: user.username,
          preferred_username: user.username,
          given_name: user.first_name.presence,
          family_name: user.last_name.presence,
          email: user.email,
          email_verified: user.primary_email_verified?,
          website: (user.full_website_url if user.website_url.present?),
          profile: Gitlab::Routing.url_helpers.user_url(user),
          picture: user.avatar_url(only_path: false),
          groups_direct: user.direct_groups_full_paths
        }

        # Not compact_blank: that would also drop `email_verified: false`
        # and `groups_direct: []`, both valid claim values. This matches
        # doorkeeper-openid_connect's own UserInfo/IdToken#as_json filter.
        raw_claims.reject { |_, value| value.nil? || value == '' }
      end

      private

      attr_reader :user
    end
  end
end
