module API
  # Projects API
  class DeployKeys < Grape::API
    before { authenticate! }

    get "deploy_keys" do
      authenticated_as_admin!

      keys = DeployKey.all
      present keys, with: Entities::SSHKey
    end

    resource :projects do
      before { authorize_admin_project }

      # Routing "projects/:id/keys/..." is DEPRECATED and WILL BE REMOVED in version 9.0
      # Use "projects/:id/deploy_keys/..." instead.
      #
      %w(keys deploy_keys).each do |path|
        # Get a specific project's deploy keys
        #
        # Example Request:
        #   GET /projects/:id/deploy_keys
        get ":id/#{path}" do
          present user_project.deploy_keys, with: Entities::SSHKey
        end

        # Get single deploy key owned by currently authenticated user
        #
        # Example Request:
        #   GET /projects/:id/deploy_keys/:key_id
        get ":id/#{path}/:key_id" do
          key = user_project.deploy_keys.find params[:key_id]
          present key, with: Entities::SSHKey
        end

        # Add new deploy key to currently authenticated user
        # If deploy key already exists - it will be joined to project
        # but only if original one was accessible by same user
        #
        # Parameters:
        #   key (required) - New deploy Key
        #   title (required) - New deploy Key's title
        # Example Request:
        #   POST /projects/:id/deploy_keys
        post ":id/#{path}" do
          attrs = attributes_for_keys [:title, :key]

          if attrs[:key].present?
            attrs[:key].strip!

            # check if key already exist in project
            key = user_project.deploy_keys.find_by(key: attrs[:key])
            if key
              present key, with: Entities::SSHKey
              next
            end

            # Check for available deploy keys in other projects
            key = current_user.accessible_deploy_keys.find_by(key: attrs[:key])
            if key
              user_project.deploy_keys << key
              present key, with: Entities::SSHKey
              next
            end
          end

          key = DeployKey.new attrs

          if key.valid? && user_project.deploy_keys << key
            present key, with: Entities::SSHKey
          else
            render_validation_error!(key)
          end
        end

        desc 'Enable a deploy key for a project' do
          detail 'This feature was added in GitLab 8.11'
          success Entities::SSHKey
        end
        params do
          requires :key_id, type: Integer, desc: 'The ID of the deploy key'
        end
        post ":id/#{path}/:key_id/enable" do
          key = DeployKey.find(params[:key_id])

          if user_project.deploy_keys << key
            present key, with: Entities::SSHKey
          else
            render_validation_error!(key)
          end
        end

        desc 'Disable a deploy key for a project' do
          detail 'This feature was added in GitLab 8.11'
          success Entities::SSHKey
        end
        params do
          requires :key_id, type: Integer, desc: 'The ID of the deploy key'
        end
        delete ":id/#{path}/:key_id/disable" do
          key = user_project.deploy_keys_projects.find_by(deploy_key_id: params[:key_id])
          key.destroy

          present key.deploy_key, with: Entities::SSHKey
        end

        # Delete existing deploy key of currently authenticated user
        #
        # Example Request:
        #   DELETE /projects/:id/deploy_keys/:key_id
        delete ":id/#{path}/:key_id" do
          key = user_project.deploy_keys.find params[:key_id]
          key.destroy
        end
      end
    end
  end
end
