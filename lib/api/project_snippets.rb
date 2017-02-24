module API
  class ProjectSnippets < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      helpers do
        def handle_project_member_errors(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          end
          not_found!
        end

        def snippets_for_current_user
          finder_params = { filter: :by_project, project: user_project }
          SnippetsFinder.new.execute(current_user, finder_params)
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
        requires :visibility_level, type: Integer,
                                    values: [Gitlab::VisibilityLevel::PRIVATE,
                                             Gitlab::VisibilityLevel::INTERNAL,
                                             Gitlab::VisibilityLevel::PUBLIC],
                                    desc: 'The visibility level of the snippet'
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
        optional :visibility_level, type: Integer,
                                    values: [Gitlab::VisibilityLevel::PRIVATE,
                                             Gitlab::VisibilityLevel::INTERNAL,
                                             Gitlab::VisibilityLevel::PUBLIC],
                                    desc: 'The visibility level of the snippet'
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
        snippet.destroy
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
    end
  end
end
