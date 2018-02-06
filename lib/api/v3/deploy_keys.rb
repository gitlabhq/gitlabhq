module API
  module V3
    class DeployKeys < Grape::API
      before { authenticate! }

      helpers do
        def add_deploy_keys_project(project, attrs = {})
          project.deploy_keys_projects.create(attrs)
        end

        def find_by_deploy_key(project, key_id)
          project.deploy_keys_projects.find_by!(deploy_key: key_id)
        end
      end

      get "deploy_keys" do
        authenticated_as_admin!

        keys = DeployKey.all
        present keys, with: ::API::Entities::SSHKey
      end

      params do
        requires :id, type: String, desc: 'The ID of the project'
      end
      resource :projects, requirements: { id: %r{[^/]+} } do
        before { authorize_admin_project }

        %w(keys deploy_keys).each do |path|
          desc "Get a specific project's deploy keys" do
            success ::API::Entities::DeployKeysProject
          end
          get ":id/#{path}" do
            keys = user_project.deploy_keys_projects.preload(:deploy_key)

            present keys, with: ::API::Entities::DeployKeysProject
          end

          desc 'Get single deploy key' do
            success ::API::Entities::DeployKeysProject
          end
          params do
            requires :key_id, type: Integer, desc: 'The ID of the deploy key'
          end
          get ":id/#{path}/:key_id" do
            key = find_by_deploy_key(user_project, params[:key_id])

            present key, with: ::API::Entities::DeployKeysProject
          end

          desc 'Add new deploy key to currently authenticated user' do
            success ::API::Entities::DeployKeysProject
          end
          params do
            requires :key, type: String, desc: 'The new deploy key'
            requires :title, type: String, desc: 'The name of the deploy key'
            optional :can_push, type: Boolean, desc: "Can deploy key push to the project's repository"
          end
          post ":id/#{path}" do
            params[:key].strip!

            # Check for an existing key joined to this project
            key = user_project.deploy_keys_projects
                              .joins(:deploy_key)
                              .find_by(keys: { key: params[:key] })

            if key
              present key, with: ::API::Entities::DeployKeysProject
              break
            end

            # Check for available deploy keys in other projects
            key = current_user.accessible_deploy_keys.find_by(key: params[:key])
            if key
              added_key = add_deploy_keys_project(user_project, deploy_key: key, can_push: !!params[:can_push])

              present added_key, with: ::API::Entities::DeployKeysProject
              break
            end

            # Create a new deploy key
            key_attributes = { can_push: !!params[:can_push],
                               deploy_key_attributes: declared_params.except(:can_push) }
            key = add_deploy_keys_project(user_project, key_attributes)

            if key.valid?
              present key, with: ::API::Entities::DeployKeysProject
            else
              render_validation_error!(key)
            end
          end

          desc 'Enable a deploy key for a project' do
            detail 'This feature was added in GitLab 8.11'
            success ::API::Entities::SSHKey
          end
          params do
            requires :key_id, type: Integer, desc: 'The ID of the deploy key'
          end
          post ":id/#{path}/:key_id/enable" do
            key = ::Projects::EnableDeployKeyService.new(user_project,
                                                          current_user, declared_params).execute

            if key
              present key, with: ::API::Entities::SSHKey
            else
              not_found!('Deploy Key')
            end
          end

          desc 'Disable a deploy key for a project' do
            detail 'This feature was added in GitLab 8.11'
            success ::API::Entities::SSHKey
          end
          params do
            requires :key_id, type: Integer, desc: 'The ID of the deploy key'
          end
          delete ":id/#{path}/:key_id/disable" do
            key = user_project.deploy_keys_projects.find_by(deploy_key_id: params[:key_id])
            key.destroy

            present key.deploy_key, with: ::API::Entities::SSHKey
          end

          desc 'Delete deploy key for a project' do
            success Key
          end
          params do
            requires :key_id, type: Integer, desc: 'The ID of the deploy key'
          end
          delete ":id/#{path}/:key_id" do
            key = user_project.deploy_keys_projects.find_by(deploy_key_id: params[:key_id])
            if key
              key.destroy
            else
              not_found!('Deploy Key')
            end
          end
        end
      end
    end
  end
end
