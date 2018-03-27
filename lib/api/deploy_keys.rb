module API
  class DeployKeys < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers do
      def add_deploy_keys_project(project, attrs = {})
        project.deploy_keys_projects.create(attrs)
      end

      def find_by_deploy_key(project, key_id)
        project.deploy_keys_projects.find_by!(deploy_key: key_id)
      end
    end

    desc 'Return all deploy keys'
    params do
      use :pagination
    end
    get "deploy_keys" do
      authenticated_as_admin!

      present paginate(DeployKey.all), with: Entities::SSHKey
    end

    params do
      requires :id, type: String, desc: 'The ID of the project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      before { authorize_admin_project }

      desc "Get a specific project's deploy keys" do
        success Entities::DeployKeysProject
      end
      params do
        use :pagination
      end
      get ":id/deploy_keys" do
        keys = user_project.deploy_keys_projects.preload(:deploy_key)

        present paginate(keys), with: Entities::DeployKeysProject
      end

      desc 'Get single deploy key' do
        success Entities::DeployKeysProject
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      get ":id/deploy_keys/:key_id" do
        key = find_by_deploy_key(user_project, params[:key_id])

        present key, with: Entities::DeployKeysProject
      end

      desc 'Add new deploy key to currently authenticated user' do
        success Entities::DeployKeysProject
      end
      params do
        requires :key, type: String, desc: 'The new deploy key'
        requires :title, type: String, desc: 'The name of the deploy key'
        optional :can_push, type: Boolean, desc: "Can deploy key push to the project's repository"
      end
      post ":id/deploy_keys" do
        params[:key].strip!

        # Check for an existing key joined to this project
        key = user_project.deploy_keys_projects
                          .joins(:deploy_key)
                          .find_by(keys: { key: params[:key] })

        if key
          present key, with: Entities::DeployKeysProject
          break
        end

        # Check for available deploy keys in other projects
        key = current_user.accessible_deploy_keys.find_by(key: params[:key])
        if key
          added_key = add_deploy_keys_project(user_project, deploy_key: key, can_push: !!params[:can_push])

          present added_key, with: Entities::DeployKeysProject
          break
        end

        # Create a new deploy key
        key_attributes = { can_push: !!params[:can_push],
                           deploy_key_attributes: declared_params.except(:can_push) }
        key = add_deploy_keys_project(user_project, key_attributes)

        if key.valid?
          present key, with: Entities::DeployKeysProject
        else
          render_validation_error!(key)
        end
      end

      desc 'Update an existing deploy key for a project' do
        success Entities::SSHKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
        optional :title, type: String, desc: 'The name of the deploy key'
        optional :can_push, type: Boolean, desc: "Can deploy key push to the project's repository"
        at_least_one_of :title, :can_push
      end
      put ":id/deploy_keys/:key_id" do
        deploy_keys_project = find_by_deploy_key(user_project, params[:key_id])

        authorize!(:update_deploy_key, deploy_keys_project.deploy_key)

        can_push = params[:can_push].nil? ? deploy_keys_project.can_push : params[:can_push]
        title = params[:title] || deploy_keys_project.deploy_key.title

        result = deploy_keys_project.update_attributes(can_push: can_push,
                                                       deploy_key_attributes: { id: params[:key_id],
                                                                                title: title })

        if result
          present deploy_keys_project, with: Entities::DeployKeysProject
        else
          render_validation_error!(deploy_keys_project)
        end
      end

      desc 'Enable a deploy key for a project' do
        detail 'This feature was added in GitLab 8.11'
        success Entities::SSHKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      post ":id/deploy_keys/:key_id/enable" do
        key = ::Projects::EnableDeployKeyService.new(user_project,
                                                      current_user, declared_params).execute

        if key
          present key, with: Entities::SSHKey
        else
          not_found!('Deploy Key')
        end
      end

      desc 'Delete deploy key for a project' do
        success Key
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      delete ":id/deploy_keys/:key_id" do
        key = user_project.deploy_keys.find(params[:key_id])
        not_found!('Deploy Key') unless key

        destroy_conditionally!(key)
      end
    end
  end
end
