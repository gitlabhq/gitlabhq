# frozen_string_literal: true

module API
  class ProtectedTags < ::API::Base
    include PaginationParams

    TAG_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(name: API::NO_SLASH_URL_PART_REGEX)

    feature_category :source_code_management

    helpers Helpers::ProtectedTagsHelpers

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "Get a project's protected tags" do
        detail 'This feature was introduced in GitLab 11.3.'
        is_array true
        success code: 200, model: Entities::ProtectedTag
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[protected_tags]
      end
      params do
        use :pagination
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/protected_tags' do
        authorize!(:read_protected_tags, user_project)
        protected_tags = user_project.protected_tags.preload(:create_access_levels)

        present paginate(protected_tags), with: Entities::ProtectedTag, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Get a single protected tag' do
        detail 'This feature was introduced in GitLab 11.3.'
        success code: 200, model: Entities::ProtectedTag
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[protected_tags]
      end
      params do
        requires :name, type: String, desc: 'The name of the tag or wildcard', documentation: { example: 'release*' }
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/protected_tags/:name', requirements: TAG_ENDPOINT_REQUIREMENTS do
        authorize!(:read_protected_tags, user_project)
        protected_tag = user_project.protected_tags.find_by!(name: params[:name])

        present protected_tag, with: Entities::ProtectedTag, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Protect a single tag or wildcard' do
        detail 'This feature was introduced in GitLab 11.3.'
        success code: 201, model: Entities::ProtectedTag
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[protected_tags]
      end
      params do
        requires :name, type: String, desc: 'The name of the protected tag', documentation: { example: 'release-1-0' }
        optional :create_access_level,
          type: Integer,
          values: ProtectedTag::CreateAccessLevel.allowed_access_levels,
          desc: 'Access levels allowed to create (defaults: `40`, maintainer access level)',
          documentation: { example: 30 }
        use :optional_params_ee
      end
      post ':id/protected_tags' do
        authorize!(:create_protected_tags, user_project)
        protected_tags_params = {
          name: params[:name],
          create_access_levels_attributes: ::ProtectedRefs::AccessLevelParams.new(:create, params).access_levels
        }

        protected_tag = ::ProtectedTags::CreateService.new(user_project,
          current_user,
          protected_tags_params).execute

        if protected_tag.persisted?
          present protected_tag, with: Entities::ProtectedTag, project: user_project
        else
          render_api_error!(protected_tag.errors.full_messages, 422)
        end
      end

      desc 'Unprotect a single tag' do
        detail 'This feature was introduced in GitLab 11.3.'
        success code: 204
        failure [
          { code: 403, message: 'Unauthenticated' },
          { code: 404, message: 'Not found' },
          { code: 412, message: 'Precondition Failed' }
        ]
        tags %w[protected_tags]
      end
      params do
        requires :name, type: String, desc: 'The name of the protected tag', documentation: { example: 'release-1-0' }
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ':id/protected_tags/:name', requirements: TAG_ENDPOINT_REQUIREMENTS do
        authorize!(:destroy_protected_tags, user_project)

        protected_tag = user_project.protected_tags.find_by!(name: params[:name])

        destroy_conditionally!(protected_tag) do
          destroy_service = ::ProtectedTags::DestroyService.new(user_project, current_user)
          destroy_service.execute(protected_tag)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
