module API
  class ProjectSnippets < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      helpers do
        def handle_project_member_errors(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          end

          not_found!
        end

        def snippets_for_current_user
          SnippetsFinder.new(current_user, project: user_project).execute
        end
      end

      desc 'Get all project snippets' do
        success Entities::ProjectSnippet
      end
      params do
        use :pagination
      end
      get ":id/snippets" do
        present paginate(snippets_for_current_user), with: Entities::ProjectSnippet
      end

      desc 'Get a single project snippet' do
        success Entities::ProjectSnippet
      end
      params do
        requires :snippet_id, type: Integer, desc: 'The ID of a project snippet'
      end
      get ":id/snippets/:snippet_id" do
        snippet = snippets_for_current_user.find(params[:snippet_id])
        present snippet, with: Entities::ProjectSnippet
      end

      desc 'Create a new project snippet' do
        success Entities::ProjectSnippet
      end
      params do
        requires :title, type: String, desc: 'The title of the snippet'
        requires :file_name, type: String, desc: 'The file name of the snippet'
        requires :code, type: String, desc: 'The content of the snippet'
        optional :description, type: String, desc: 'The description of a snippet'
        requires :visibility, type: String,
                              values: Gitlab::VisibilityLevel.string_values,
                              desc: 'The visibility of the snippet'
      end
      post ":id/snippets" do
        authorize! :create_project_snippet, user_project
        snippet_params = declared_params.merge(request: request, api: true)
        snippet_params[:content] = snippet_params.delete(:code)

        snippet = CreateSnippetService.new(user_project, current_user, snippet_params).execute

        render_spam_error! if snippet.spam?

        if snippet.persisted?
          present snippet, with: Entities::ProjectSnippet
        else
          render_validation_error!(snippet)
        end
      end

      desc 'Update an existing project snippet' do
        success Entities::ProjectSnippet
      end
      params do
        requires :snippet_id, type: Integer, desc: 'The ID of a project snippet'
        optional :title, type: String, desc: 'The title of the snippet'
        optional :file_name, type: String, desc: 'The file name of the snippet'
        optional :code, type: String, desc: 'The content of the snippet'
        optional :description, type: String, desc: 'The description of a snippet'
        optional :visibility, type: String,
                              values: Gitlab::VisibilityLevel.string_values,
                              desc: 'The visibility of the snippet'
        at_least_one_of :title, :file_name, :code, :visibility_level
      end
      put ":id/snippets/:snippet_id" do
        snippet = snippets_for_current_user.find_by(id: params.delete(:snippet_id))
        not_found!('Snippet') unless snippet

        authorize! :update_project_snippet, snippet

        snippet_params = declared_params(include_missing: false)
          .merge(request: request, api: true)

        snippet_params[:content] = snippet_params.delete(:code) if snippet_params[:code].present?

        UpdateSnippetService.new(user_project, current_user, snippet,
                                 snippet_params).execute

        render_spam_error! if snippet.spam?

        if snippet.valid?
          present snippet, with: Entities::ProjectSnippet
        else
          render_validation_error!(snippet)
        end
      end

      desc 'Delete a project snippet'
      params do
        requires :snippet_id, type: Integer, desc: 'The ID of a project snippet'
      end
      delete ":id/snippets/:snippet_id" do
        snippet = snippets_for_current_user.find_by(id: params[:snippet_id])
        not_found!('Snippet') unless snippet

        authorize! :admin_project_snippet, snippet

        destroy_conditionally!(snippet)
      end

      desc 'Get a raw project snippet'
      params do
        requires :snippet_id, type: Integer, desc: 'The ID of a project snippet'
      end
      get ":id/snippets/:snippet_id/raw" do
        snippet = snippets_for_current_user.find_by(id: params[:snippet_id])
        not_found!('Snippet') unless snippet

        env['api.format'] = :txt
        content_type 'text/plain'
        present snippet.content
      end

      desc 'Get the user agent details for a project snippet' do
        success Entities::UserAgentDetail
      end
      params do
        requires :snippet_id, type: Integer, desc: 'The ID of a project snippet'
      end
      get ":id/snippets/:snippet_id/user_agent_detail" do
        authenticated_as_admin!

        snippet = Snippet.find_by!(id: params[:snippet_id], project_id: params[:id])

        break not_found!('UserAgentDetail') unless snippet.user_agent_detail

        present snippet.user_agent_detail, with: Entities::UserAgentDetail
      end
    end
  end
end
