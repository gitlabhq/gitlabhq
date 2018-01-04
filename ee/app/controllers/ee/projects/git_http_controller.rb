module EE
  module Projects
    module GitHttpController
      def render_ok
        raise NotImplementedError.new unless defined?(super)

        set_workhorse_internal_api_content_type
        render json: ::Gitlab::Workhorse.git_http_ok(repository, wiki?, user, action_name, show_all_refs: geo_request?)
      end

      private

      def geo_request?
        ::Gitlab::Geo::JwtRequestDecoder.geo_auth_attempt?(request.headers['Authorization'])
      end

      def geo?
        authentication_result.geo?(project)
      end

      def access_actor
        raise NotImplementedError.new unless defined?(super)

        return :geo if geo?

        super
      end

      def authenticate_user
        raise NotImplementedError.new unless defined?(super)

        return super unless geo_request?

        payload = ::Gitlab::Geo::JwtRequestDecoder.new(request.headers['Authorization']).decode
        if payload
          @authentication_result = ::Gitlab::Auth::Result.new(nil, project, :geo, [:download_code]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
          return # grant access
        end

        render_bad_geo_auth('Bad token')
      rescue ::Gitlab::Geo::InvalidDecryptionKeyError
        render_bad_geo_auth("Invalid decryption key")
      rescue ::Gitlab::Geo::InvalidSignatureTimeError
        render_bad_geo_auth("Invalid signature time ")
      end

      def render_bad_geo_auth(message)
        render plain: "Geo JWT authentication failed: #{message}", status: 401
      end
    end
  end
end
