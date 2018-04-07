module API
  class Geo < Grape::API
    resource :geo do
      # Verify the GitLab Geo transfer request is valid
      # All transfers use the Authorization header to pass a JWT
      # payload.
      #
      # For LFS objects, validate the object ID exists in the DB
      # and that the object ID matches the requested ID. This is
      # a sanity check against some malicious client requesting
      # a random file path.
      params do
        requires :type, type: String, desc: 'File transfer type (e.g. lfs)'
        requires :id, type: Integer, desc: 'The DB ID of the file'
      end
      get 'transfers/:type/:id' do
        service = ::Geo::FileUploadService.new(params, headers['Authorization'])
        response = service.execute

        unauthorized! unless response.present?

        if response[:code] == :ok
          file = response[:file]
          present_disk_file!(file.path, file.filename)
        else
          error! response, response.delete(:code)
        end
      end

      #  Get node information (e.g. health, repos synced, repos failed, etc.)
      #
      # Example request:
      #   GET /geo/status
      get 'status' do
        authenticate_by_gitlab_geo_node_token!

        status = ::GeoNodeStatus.current_node_status
        present status, with: EE::API::Entities::GeoNodeStatus
      end
    end

    helpers do
      def authenticate_by_gitlab_geo_node_token!
        auth_header = headers['Authorization']

        begin
          unless auth_header && Gitlab::Geo::JwtRequestDecoder.new(auth_header).decode
            unauthorized!
          end
        rescue Gitlab::Geo::InvalidDecryptionKeyError, Gitlab::Geo::SignatureTimeInvalidError => e
          render_api_error!(e.to_s, 401)
        end
      end

      def require_node_to_be_enabled!
        forbidden! 'Geo node is disabled.' unless Gitlab::Geo.current_node&.enabled?
      end
    end
  end
end
