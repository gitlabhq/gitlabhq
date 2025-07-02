# frozen_string_literal: true

module Gitlab
  module Auth
    module OAuth
      class OauthResourceOwnerRedirectResolver
        include ::Gitlab::Routing

        attr_reader :top_level_namespace_path

        def initialize(top_level_namespace_path)
          @top_level_namespace_path = top_level_namespace_path
        end

        def resolve_redirect_url
          new_user_session_url
        end
      end
    end
  end
end

Gitlab::Auth::OAuth::OauthResourceOwnerRedirectResolver.prepend_mod
