# frozen_string_literal: true

module API
  class Tags < ::API::Base
    include PaginationParams

    TAG_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(tag_name: API::NO_SLASH_URL_PART_REGEX)

    before { authorize! :download_code, user_project }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a project repository tags' do
        success Entities::Tag
      end
      params do
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return tags sorted in updated by `asc` or `desc` order.'
        optional :order_by, type: String, values: %w[name updated], default: 'updated',
                            desc: 'Return tags ordered by `name` or `updated` fields.'
        optional :search, type: String, desc: 'Return list of tags matching the search criteria'
        use :pagination
      end
      get ':id/repository/tags', feature_category: :source_code_management do
        tags = ::TagsFinder.new(user_project.repository,
                                sort: "#{params[:order_by]}_#{params[:sort]}",
                                search: params[:search]).execute

        present paginate(::Kaminari.paginate_array(tags)), with: Entities::Tag, project: user_project
      end

      desc 'Get a single repository tag' do
        success Entities::Tag
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag'
      end
      get ':id/repository/tags/:tag_name', requirements: TAG_ENDPOINT_REQUIREMENTS, feature_category: :source_code_management do
        tag = user_project.repository.find_tag(params[:tag_name])
        not_found!('Tag') unless tag

        present tag, with: Entities::Tag, project: user_project
      end

      desc 'Create a new repository tag' do
        detail 'This optional release_description parameter was deprecated in GitLab 11.7.'
        success Entities::Tag
      end
      params do
        requires :tag_name,            type: String, desc: 'The name of the tag'
        requires :ref,                 type: String, desc: 'The commit sha or branch name'
        optional :message,             type: String, desc: 'Specifying a message creates an annotated tag'
        optional :release_description, type: String, desc: 'Specifying release notes stored in the GitLab database (deprecated in GitLab 11.7)'
      end
      post ':id/repository/tags', :release_orchestration do
        authorize_admin_tag

        result = ::Tags::CreateService.new(user_project, current_user)
          .execute(params[:tag_name], params[:ref], params[:message])

        if result[:status] == :success
          # Release creation with Tags API was deprecated in GitLab 11.7
          if params[:release_description].present?
            release_create_params = {
              tag: params[:tag_name],
              name: params[:tag_name], # Name can be specified in new API
              description: params[:release_description]
            }

            ::Releases::CreateService
              .new(user_project, current_user, release_create_params)
              .execute
          end

          present result[:tag],
                  with: Entities::Tag,
                  project: user_project
        else
          render_api_error!(result[:message], 400)
        end
      end

      desc 'Delete a repository tag'
      params do
        requires :tag_name, type: String, desc: 'The name of the tag'
      end
      delete ':id/repository/tags/:tag_name', requirements: TAG_ENDPOINT_REQUIREMENTS, feature_category: :source_code_management do
        authorize_admin_tag

        tag = user_project.repository.find_tag(params[:tag_name])
        not_found!('Tag') unless tag

        commit = user_project.repository.commit(tag.dereferenced_target)

        destroy_conditionally!(commit, last_updated: commit.authored_date) do
          result = ::Tags::DestroyService.new(user_project, current_user)
                    .execute(params[:tag_name])

          if result[:status] != :success
            render_api_error!(result[:message], result[:return_code])
          end
        end
      end

      desc 'Add a release note to a tag' do
        detail 'This feature was deprecated in GitLab 11.7.'
        success Entities::TagRelease
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag', as: :tag
        requires :description, type: String, desc: 'Release notes with markdown support'
      end
      post ':id/repository/tags/:tag_name/release', requirements: TAG_ENDPOINT_REQUIREMENTS, feature_category: :release_orchestration do
        authorize_create_release!

        ##
        # Legacy API does not support tag auto creation.
        not_found!('Tag') unless user_project.repository.find_tag(params[:tag])

        release_create_params = {
          tag: params[:tag],
          name: params[:tag], # Name can be specified in new API
          description: params[:description]
        }

        result = ::Releases::CreateService
          .new(user_project, current_user, release_create_params)
          .execute

        if result[:status] == :success
          present result[:release], with: Entities::TagRelease
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc "Update a tag's release note" do
        detail 'This feature was deprecated in GitLab 11.7.'
        success Entities::TagRelease
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag', as: :tag
        requires :description, type: String, desc: 'Release notes with markdown support'
      end
      put ':id/repository/tags/:tag_name/release', requirements: TAG_ENDPOINT_REQUIREMENTS, feature_category: :release_orchestration do
        authorize_update_release!

        result = ::Releases::UpdateService
          .new(user_project, current_user, declared_params(include_missing: false))
          .execute

        if result[:status] == :success
          present result[:release], with: Entities::TagRelease
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end

    helpers do
      def authorize_create_release!
        authorize! :create_release, user_project
      end

      def authorize_update_release!
        authorize! :update_release, release
      end

      def release
        @release ||= user_project.releases.find_by_tag(params[:tag])
      end
    end
  end
end
