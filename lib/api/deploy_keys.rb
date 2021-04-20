# frozen_string_literal: true

module API
  class DeployKeys < ::API::Base
    include PaginationParams

    before { authenticate! }

    feature_category :continuous_delivery

    helpers do
      def add_deploy_keys_project(project, attrs = {})
        project.deploy_keys_projects.create(attrs)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_by_deploy_key(project, key_id)
        project.deploy_keys_projects.find_by!(deploy_key: key_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    desc 'Return all deploy keys'
    params do
      use :pagination
    end
    get "deploy_keys" do
      authenticated_as_admin!

      present paginate(DeployKey.all), with: Entities::DeployKey
    end

    params do
      requires :id, type: String, desc: 'The ID of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before { authorize_admin_project }

      desc "Get a specific project's deploy keys" do
        success Entities::DeployKeysProject
      end
      params do
        use :pagination
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ":id/deploy_keys" do
        keys = user_project.deploy_keys_projects.preload(deploy_key: :user)

        present paginate(keys), with: Entities::DeployKeysProject
      end
      # rubocop: enable CodeReuse/ActiveRecord

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

      desc 'Add new deploy key to a project' do
        success Entities::DeployKeysProject
      end
      params do
        requires :key, type: String, desc: 'The new deploy key'
        requires :title, type: String, desc: 'The name of the deploy key'
        optional :can_push, type: Boolean, desc: "Can deploy key push to the project's repository"
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ":id/deploy_keys" do
        params[:key].strip!

        # Check for an existing key joined to this project
        deploy_key_project = user_project.deploy_keys_projects
                          .joins(:deploy_key)
                          .find_by(keys: { key: params[:key] })

        if deploy_key_project
          present deploy_key_project, with: Entities::DeployKeysProject
          break
        end

        # Check for available deploy keys in other projects
        key = current_user.accessible_deploy_keys.find_by(key: params[:key])
        if key
          deploy_key_project = add_deploy_keys_project(user_project, deploy_key: key, can_push: !!params[:can_push])

          present deploy_key_project, with: Entities::DeployKeysProject
          break
        end

        # Create a new deploy key
        deploy_key_attributes = declared_params.except(:can_push).merge(user: current_user)
        deploy_key_project = add_deploy_keys_project(user_project, deploy_key_attributes: deploy_key_attributes, can_push: !!params[:can_push])

        if deploy_key_project.valid?
          present deploy_key_project, with: Entities::DeployKeysProject
        else
          render_validation_error!(deploy_key_project)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Update an existing deploy key for a project' do
        success Entities::DeployKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
        optional :title, type: String, desc: 'The name of the deploy key'
        optional :can_push, type: Boolean, desc: "Can deploy key push to the project's repository"
        at_least_one_of :title, :can_push
      end
      put ":id/deploy_keys/:key_id" do
        deploy_keys_project = find_by_deploy_key(user_project, params[:key_id])

        if !can?(current_user, :update_deploy_key, deploy_keys_project.deploy_key) &&
            !can?(current_user, :update_deploy_keys_project, deploy_keys_project)
          forbidden!(nil)
        end

        update_params = {}
        update_params[:can_push] = params[:can_push] if params.key?(:can_push)
        update_params[:deploy_key_attributes] = { id: params[:key_id] }

        if can?(current_user, :update_deploy_key, deploy_keys_project.deploy_key)
          update_params[:deploy_key_attributes][:title] = params[:title] if params.key?(:title)
        end

        result = deploy_keys_project.update(update_params)

        if result
          present deploy_keys_project, with: Entities::DeployKeysProject
        else
          render_validation_error!(deploy_keys_project)
        end
      end

      desc 'Enable a deploy key for a project' do
        detail 'This feature was added in GitLab 8.11'
        success Entities::DeployKey
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      post ":id/deploy_keys/:key_id/enable" do
        key = ::Projects::EnableDeployKeyService.new(user_project,
                                                      current_user, declared_params).execute

        if key
          present key, with: Entities::DeployKey
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
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/deploy_keys/:key_id" do
        deploy_key_project = user_project.deploy_keys_projects.find_by(deploy_key_id: params[:key_id])
        not_found!('Deploy Key') unless deploy_key_project

        destroy_conditionally!(deploy_key_project)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
