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

      # Post current node information to primary (e.g. health, repos synced, repos failed, etc.)
      #
      # Example request:
      #   POST /geo/status
      post 'status' do
        authenticate_by_gitlab_geo_node_token!

        db_status = GeoNode.find(params[:geo_node_id]).find_or_build_status

        unless db_status.update(params.merge(last_successful_status_check_at: Time.now.utc))
          render_validation_error!(db_status)
        end
      end
    end
  end
end
