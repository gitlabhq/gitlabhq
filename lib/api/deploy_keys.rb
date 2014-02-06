module API
  # Projects API
  class DeployKeys < Grape::API
    before { authenticate! }
    before { authorize_admin_project }

    resource :projects do
      # Get a specific project's keys
      #
      # Example Request:
      #   GET /projects/:id/keys
      get ":id/keys" do
        present user_project.deploy_keys, with: Entities::SSHKey
      end

      # Get single key owned by currently authenticated user
      #
      # Example Request:
      #   GET /projects/:id/keys/:id
      get ":id/keys/:key_id" do
        key = user_project.deploy_keys.find params[:key_id]
        present key, with: Entities::SSHKey
      end

      # Add new ssh key to currently authenticated user
      # If deploy key already exists - it will be joined to project
      # but only if original one was is accessible by same user
      #
      # Parameters:
      #   key (required) - New SSH Key
      #   title (required) - New SSH Key's title
      # Example Request:
      #   POST /projects/:id/keys
      post ":id/keys" do
        attrs = attributes_for_keys [:title, :key]

        if attrs[:key].present?
          attrs[:key].strip!

          # check if key already exist in project
          key = user_project.deploy_keys.find_by(key: attrs[:key])
          if key
            present key, with: Entities::SSHKey
            return
          end

          # Check for available deploy keys in other projects
          key = current_user.accessible_deploy_keys.find_by(key: attrs[:key])
          if key
            user_project.deploy_keys << key
            present key, with: Entities::SSHKey
            return
          end
        end

        key = DeployKey.new attrs

        if key.valid? && user_project.deploy_keys << key
          present key, with: Entities::SSHKey
        else
          not_found!
        end
      end

      # Delete existed ssh key of currently authenticated user
      #
      # Example Request:
      #   DELETE /projects/:id/keys/:id
      delete ":id/keys/:key_id" do
        key = user_project.deploy_keys.find params[:key_id]
        key.destroy
      end
    end
  end
end
