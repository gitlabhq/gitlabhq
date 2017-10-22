module API
  class ProtectedTags < Grape::API
    include PaginationParams

    TAG_ENDPOINT_REQUIREMENTS = API::PROJECT_ENDPOINT_REQUIREMENTS.merge(branch: API::NO_SLASH_URL_PART_REGEX)

    before { authorize_admin_project }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc "Get a project's protected tags" do
        success Entities::ProtectedTag
      end
      params do
        use :pagination
      end
      get ':id/protected_tags' do
        protected_tags = user_project.protected_tags.preload(:create_access_levels)

        present paginate(protected_tags), with: Entities::ProtectedTag, project: user_project
      end

      desc 'Get a single protected tag' do
        success Entities::ProtectedTag
      end
      params do
        requires :name, type: String, desc: 'The name of the tag or wildcard'
      end
      get ':id/protected_tags/:name', requirements: TAG_ENDPOINT_REQUIREMENTS do
        protected_tags = user_project.protected_tags.find_by!(name: params[:name])

        present protected_tags, with: Entities::ProtectedTag, project: user_project
      end

      desc 'Protect a single tag or wildcard' do
        success Entities::ProtectedTag
      end
      params do
        requires :name, type: String, desc: 'The name of the protected tag'
        optional :create_access_level, type: Integer, default: Gitlab::Access::MASTER,
                                       values: ProtectedTagAccess::ALLOWED_ACCESS_LEVELS,
                                       desc: 'Access levels allowed to create (defaults: `40`, master access level)'
      end
      post ':id/protected_tags' do
        protected_tags = user_project.protected_tags.find_by(name: params[:name])
        if protected_tags
          conflict!("Protected tag '#{params[:name]}' already exists")
        end

        protected_tags_params = {
          name: params[:name],
          create_access_levels_attributes: [{ access_level: params[:create_access_level] }]
        }

        service_args = [user_project, current_user, protected_tags_params]

        protected_tags = ::ProtectedTags::CreateService.new(*service_args).execute

        if protected_tags.persisted?
          present protected_tags, with: Entities::ProtectedTag, project: user_project
        else
          render_api_error!(protected_tags.errors.full_messages, 422)
        end
      end

      desc 'Unprotect a single tag'
      params do
        requires :name, type: String, desc: 'The name of the protected tag'
      end
      delete ':id/protected_tags/:name', requirements: TAG_ENDPOINT_REQUIREMENTS do
        protected_tags = user_project.protected_tags.find_by!(name: params[:name])

        destroy_conditionally!(protected_tags)
      end
    end
  end
end
