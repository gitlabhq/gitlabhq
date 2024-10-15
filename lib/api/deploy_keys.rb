# frozen_string_literal: true

module API
  class DeployKeys < ::API::Base
    include PaginationParams

    deploy_keys_tags = %w[deploy_keys]

    before { authenticate! }

    feature_category :continuous_delivery
    urgency :low

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

    desc 'List all deploy keys' do
      detail 'Get a list of all deploy keys across all projects of the GitLab instance. This endpoint requires administrator access and is not available on GitLab.com.'
      success Entities::DeployKey
      failure [
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' }
      ]
      is_array true
      tags deploy_keys_tags
    end
    params do
      use :pagination
      optional :public, type: Boolean, default: false, desc: "Only return deploy keys that are public"
    end
    get "deploy_keys" do
      authenticated_as_admin!

      deploy_keys = params[:public] ? DeployKey.are_public : DeployKey.all
      deploy_keys = deploy_keys.including_projects_with_write_access.including_projects_with_readonly_access

      present paginate(deploy_keys),
        with: Entities::DeployKey, include_projects_with_write_access: true, include_projects_with_readonly_access: true
    end

    desc 'Create a deploy key' do
      detail 'Create a deploy key for the GitLab instance. This endpoint requires administrator access.'
      success Entities::DeployKey
      failure [
        { code: 400, message: 'Bad request' },
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' }
      ]
      tags deploy_keys_tags
    end
    params do
      requires :key, type: String, desc: 'New deploy key'
      requires :title, type: String, desc: "New deploy key's title"
      optional :expires_at, type: DateTime, desc: 'The expiration date of the SSH key in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)'
    end
    post "deploy_keys" do
      authenticated_as_admin!

      deploy_key = ::DeployKeys::CreateService.new(current_user, declared_params.merge(public: true)).execute

      if deploy_key.persisted?
        present deploy_key, with: Entities::DeployKey
      else
        render_validation_error!(deploy_key)
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before { authorize_admin_project }

      desc 'List deploy keys for project' do
        detail "Get a list of a project's deploy keys."
        success Entities::DeployKeysProject
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags deploy_keys_tags
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

      desc 'Get a single deploy key' do
        detail 'Get a single key.'
        success Entities::DeployKeysProject
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_keys_tags
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      get ":id/deploy_keys/:key_id" do
        key = find_by_deploy_key(user_project, params[:key_id])

        present key, with: Entities::DeployKeysProject
      end

      desc 'Add deploy key' do
        detail "Creates a new deploy key for a project. If the deploy key already exists in another project, it's joined to the current project only if the original one is accessible by the same user."
        success Entities::DeployKeysProject
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_keys_tags
      end
      params do
        requires :key, type: String, desc: 'New deploy key'
        requires :title, type: String, desc: "New deploy key's title"
        optional :can_push, type: Boolean, desc: "Can deploy key push to the project's repository"
        optional :expires_at, type: DateTime, desc: 'The expiration date of the SSH key in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)'
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

      desc 'Update deploy key' do
        detail 'Updates a deploy key for a project.'
        success Entities::DeployKey
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_keys_tags
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
        optional :title, type: String, desc: "New deploy key's title"
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

        if can?(current_user, :update_deploy_key_title, deploy_keys_project.deploy_key)
          update_params[:deploy_key_attributes][:title] = params[:title] if params.key?(:title)
        end

        result = deploy_keys_project.update(update_params)

        if result
          present deploy_keys_project, with: Entities::DeployKeysProject
        else
          render_validation_error!(deploy_keys_project)
        end
      end

      desc 'Enable a deploy key' do
        detail 'Enables a deploy key for a project so this can be used. Returns the enabled key, with a status code 201 when successful. This feature was added in GitLab 8.11.'
        success Entities::DeployKey
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_keys_tags
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
          not_found!('Deploy key')
        end
      end

      desc 'Delete deploy key' do
        detail "Removes a deploy key from the project. If the deploy key is used only for this project, it's deleted from the system."
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags deploy_keys_tags
      end
      params do
        requires :key_id, type: Integer, desc: 'The ID of the deploy key'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/deploy_keys/:key_id" do
        deploy_key_project = user_project.deploy_keys_projects.find_by(deploy_key_id: params[:key_id])
        not_found!('Deploy key') unless deploy_key_project

        destroy_conditionally!(deploy_key_project)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
