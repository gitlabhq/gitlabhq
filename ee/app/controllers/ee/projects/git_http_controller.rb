module EE
  module Projects
    module GitHttpController
      extend ::Gitlab::Utils::Override

      override :render_ok
      def render_ok
        set_workhorse_internal_api_content_type

        render json: ::Gitlab::Workhorse.git_http_ok(repository, wiki?, user, action_name, show_all_refs: geo_request?)
      end

      private

      def user
        super || geo_push_user&.user
      end

      def geo_push_user
        @geo_push_user ||= ::Geo::PushUser.new_from_headers(request.headers)
      end

      def geo_push_user_headers_provided?
        ::Geo::PushUser.needed_headers_provided?(request.headers)
      end

      def geo_request?
        ::Gitlab::Geo::JwtRequestDecoder.geo_auth_attempt?(request.headers['Authorization'])
      end

      def geo?
        authentication_result.geo?(project)
      end

      override :access_actor
      def access_actor
        return super unless geo?
        return :geo unless geo_push_user_headers_provided?
        return geo_push_user.user if geo_push_user.user

        raise ::Gitlab::GitAccess::UnauthorizedError, 'Geo push user is invalid.'
      end

      override :authenticate_user
      def authenticate_user
        return super unless geo_request?

        payload = ::Gitlab::Geo::JwtRequestDecoder.new(request.headers['Authorization']).decode
        if payload
          @authentication_result = ::Gitlab::Auth::Result.new(nil, project, :geo, [:download_code, :push_code]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
          return # grant access
        end

        render_bad_geo_auth('Bad token')
      rescue ::Gitlab::Geo::InvalidDecryptionKeyError
        render_bad_geo_auth("Invalid decryption key")
      rescue ::Gitlab::Geo::InvalidSignatureTimeError
        render_bad_geo_auth("Invalid signature time ")
      end

      def render_bad_geo_auth(message)
        render plain: "Geo JWT authentication failed: #{message}", status: :unauthorized
      end
    end
  end
end
