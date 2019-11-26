# frozen_string_literal: true

module API
  # Snippets API
  class Snippets < Grape::API
    include PaginationParams

    before { authenticate! }

    resource :snippets do
      helpers do
        def snippets_for_current_user
          SnippetsFinder.new(current_user, author: current_user).execute
        end

        def public_snippets
          Snippet.only_personal_snippets.are_public.fresh
        end

        def snippets
          SnippetsFinder.new(current_user).execute
        end
      end

      desc 'Get a snippets list for authenticated user' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
      end
      params do
        use :pagination
      end
      get do
        present paginate(snippets_for_current_user), with: Entities::PersonalSnippet
      end

      desc 'List all public personal snippets current_user has access to' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
      end
      params do
        use :pagination
      end
      get 'public' do
        present paginate(public_snippets), with: Entities::PersonalSnippet
      end

      desc 'Get a single snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
      end
      get ':id' do
        snippet = snippets.find_by_id(params[:id])

        break not_found!('Snippet') unless snippet

        present snippet, with: Entities::PersonalSnippet
      end

      desc 'Create new snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
      end
      params do
        requires :title, type: String, desc: 'The title of a snippet'
        requires :file_name, type: String, desc: 'The name of a snippet file'
        requires :content, type: String, desc: 'The content of a snippet'
        optional :description, type: String, desc: 'The description of a snippet'
        optional :visibility, type: String,
                              values: Gitlab::VisibilityLevel.string_values,
                              default: 'internal',
                              desc: 'The visibility of the snippet'
      end
      post do
        attrs = declared_params(include_missing: false).merge(request: request, api: true)
        snippet = CreateSnippetService.new(nil, current_user, attrs).execute

        render_spam_error! if snippet.spam?

        if snippet.persisted?
          present snippet, with: Entities::PersonalSnippet
        else
          render_validation_error!(snippet)
        end
      end

      desc 'Update an existing snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
        optional :title, type: String, desc: 'The title of a snippet'
        optional :file_name, type: String, desc: 'The name of a snippet file'
        optional :content, type: String, desc: 'The content of a snippet'
        optional :description, type: String, desc: 'The description of a snippet'
        optional :visibility, type: String,
                              values: Gitlab::VisibilityLevel.string_values,
                              desc: 'The visibility of the snippet'
        at_least_one_of :title, :file_name, :content, :visibility
      end
      put ':id' do
        snippet = snippets_for_current_user.find_by_id(params.delete(:id))
        break not_found!('Snippet') unless snippet

        authorize! :update_personal_snippet, snippet

        attrs = declared_params(include_missing: false).merge(request: request, api: true)

        UpdateSnippetService.new(nil, current_user, snippet, attrs).execute

        render_spam_error! if snippet.spam?

        if snippet.persisted?
          present snippet, with: Entities::PersonalSnippet
        else
          render_validation_error!(snippet)
        end
      end

      desc 'Remove snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
      end
      delete ':id' do
        snippet = snippets_for_current_user.find_by_id(params.delete(:id))
        break not_found!('Snippet') unless snippet

        authorize! :admin_personal_snippet, snippet

        destroy_conditionally!(snippet)
      end

      desc 'Get a raw snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
      end
      get ":id/raw" do
        snippet = snippets.find_by_id(params.delete(:id))
        break not_found!('Snippet') unless snippet

        env['api.format'] = :txt
        content_type 'text/plain'
        header['Content-Disposition'] = 'attachment'
        present snippet.content
      end

      desc 'Get the user agent details for a snippet' do
        success Entities::UserAgentDetail
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
      end
      get ":id/user_agent_detail" do
        authenticated_as_admin!

        snippet = Snippet.find_by_id!(params[:id])

        break not_found!('UserAgentDetail') unless snippet.user_agent_detail

        present snippet.user_agent_detail, with: Entities::UserAgentDetail
      end
    end
  end
end
