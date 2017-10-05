module API
  module V3
    class Tags < Grape::API
      before { authorize! :download_code, user_project }

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: { id: %r{[^/]+} } do
        desc 'Get a project repository tags' do
          success ::API::Entities::Tag
        end
        get ":id/repository/tags" do
          tags = user_project.repository.tags.sort_by(&:name).reverse
          present tags, with: ::API::Entities::Tag, project: user_project
        end

        desc 'Delete a repository tag'
        params do
          requires :tag_name, type: String, desc: 'The name of the tag'
        end
        delete ":id/repository/tags/:tag_name", requirements: { tag_name: /.+/ } do
          authorize_push_project

          result = ::Tags::DestroyService.new(user_project, current_user)
            .execute(params[:tag_name])

          if result[:status] == :success
            status(200)
            {
              tag_name: params[:tag_name]
            }
          else
            render_api_error!(result[:message], result[:return_code])
          end
        end
      end
    end
  end
end
