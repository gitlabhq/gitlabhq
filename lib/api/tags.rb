module API
  class Tags < Grape::API
    include PaginationParams

    TAG_ENDPOINT_REQUIREMENTS = API::PROJECT_ENDPOINT_REQUIREMENTS.merge(tag_name: API::NO_SLASH_URL_PART_REGEX)

    before { authorize! :download_code, user_project }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get a project repository tags' do
        success Entities::Tag
      end
      params do
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return tags sorted in updated by `asc` or `desc` order.'
        optional :order_by, type: String, values: %w[name updated], default: 'updated',
                            desc: 'Return tags ordered by `name` or `updated` fields.'
        use :pagination
      end
      get ':id/repository/tags' do
        tags = ::Kaminari.paginate_array(::TagsFinder.new(user_project.repository, sort: "#{params[:order_by]}_#{params[:sort]}").execute)

        present paginate(tags), with: Entities::Tag, project: user_project
      end

      desc 'Get a single repository tag' do
        success Entities::Tag
      end
      params do
        requires :tag_name, type: String, desc: 'The name of the tag'
      end
      get ':id/repository/tags/:tag_name', requirements: TAG_ENDPOINT_REQUIREMENTS do
        tag = user_project.repository.find_tag(params[:tag_name])
        not_found!('Tag') unless tag

        present tag, with: Entities::Tag, project: user_project
      end

      desc 'Create a new repository tag' do
        success Entities::Tag
      end
      params do
        requires :tag_name,            type: String, desc: 'The name of the tag'
        requires :ref,                 type: String, desc: 'The commit sha or branch name'
        optional :message,             type: String, desc: 'Specifying a message creates an annotated tag'
        optional :release_description, type: String, desc: 'Specifying release notes stored in the GitLab database'
      end
      post ':id/repository/tags' do
        authorize_push_project

        result = ::Tags::CreateService.new(user_project, current_user)
          .execute(params[:tag_name], params[:ref], params[:message], params[:release_description])

        if result[:status] == :success
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
      delete ':id/repository/tags/:tag_name', requirements: TAG_ENDPOINT_REQUIREMENTS do
        authorize_push_project

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
        success Entities::Release
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag'
        requires :description, type: String, desc: 'Release notes with markdown support'
      end
      post ':id/repository/tags/:tag_name/release', requirements: TAG_ENDPOINT_REQUIREMENTS do
        authorize_push_project

        result = CreateReleaseService.new(user_project, current_user)
          .execute(params[:tag_name], params[:description])

        if result[:status] == :success
          present result[:release], with: Entities::Release
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      desc "Update a tag's release note" do
        success Entities::Release
      end
      params do
        requires :tag_name,    type: String, desc: 'The name of the tag'
        requires :description, type: String, desc: 'Release notes with markdown support'
      end
      put ':id/repository/tags/:tag_name/release', requirements: TAG_ENDPOINT_REQUIREMENTS do
        authorize_push_project

        result = UpdateReleaseService.new(user_project, current_user)
          .execute(params[:tag_name], params[:description])

        if result[:status] == :success
          present result[:release], with: Entities::Release
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end
  end
end
