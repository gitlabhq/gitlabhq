module API
  # Projects API
  class DeployKeys < Grape::API
    before { authenticate! }

    get "deploy_keys" do
      authenticated_as_admin!

      keys = DeployKey.all
      present keys, with: Entities::SSHKey
    end

    params do
      requires :id, type: String, desc: 'The ID of the project'
    end
    resource :projects do
      before { authorize_admin_project }

      # Routing "projects/:id/keys/..." is DEPRECATED and WILL BE REMOVED in version 9.0
      # Use "projects/:id/deploy_keys/..." instead.
      #
      %w(keys deploy_keys).each do |path|
        desc "Get a specific project's deploy keys" do
          success Entities::SSHKey
        end
        get ":id/#{path}" do
          present user_project.deploy_keys, with: Entities::SSHKey
        end

        desc 'Get single deploy key' do
          success Entities::SSHKey
        end
        params do
          requires :key_id, type: Integer, desc: 'The ID of the deploy key'
        end
        get ":id/#{path}/:key_id" do
          key = user_project.deploy_keys.find params[:key_id]
          present key, with: Entities::SSHKey
        end

        # TODO: for 9.0 we should check if params are there with the params block
        # grape provides, at this point we'd change behaviour so we can't
        # Behaviour now if you don't provide all required params: it renders a
        # validation error or two.
        desc 'Add new deploy key to currently authenticated user' do
          success Entities::SSHKey
        end
        post ":id/#{path}" do
          attrs = attributes_for_keys [:title, :key]
          attrs[:key].strip! if attrs[:key]

          key = user_project.deploy_keys.find_by(key: attrs[:key])
          present key, with: Entities::SSHKey if key

          # Check for available deploy keys in other projects
          key = current_user.accessible_deploy_keys.find_by(key: attrs[:key])
          if key
            user_project.deploy_keys << key
            present key, with: Entities::SSHKey
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
          key = ::Projects::EnableDeployKeyService.new(user_project,
                                                        current_user, declared(params)).execute

          if key
            present key, with: Entities::SSHKey
          else
            not_found!('Deploy Key')
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

        desc 'Delete existing deploy key of currently authenticated user' do
          success Key
        end
        params do
          requires :key_id, type: Integer, desc: 'The ID of the deploy key'
        end
        delete ":id/#{path}/:key_id" do
          key = user_project.deploy_keys.find(params[:key_id])
          key.destroy
        end
      end
    end
  end
end
