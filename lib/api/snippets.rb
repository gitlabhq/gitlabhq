# frozen_string_literal: true

module API
  # Snippets API
  class Snippets < Grape::API
    include PaginationParams

    before { authenticate! }

    resource :snippets do
      helpers Helpers::SnippetsHelpers
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
        success Entities::Snippet
      end
      params do
        use :pagination
      end
      get do
        present paginate(snippets_for_current_user), with: Entities::Snippet
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
        requires :title, type: String, allow_blank: false, desc: 'The title of a snippet'
        requires :file_name, type: String, desc: 'The name of a snippet file'
        requires :content, type: String, allow_blank: false, desc: 'The content of a snippet'
        optional :description, type: String, desc: 'The description of a snippet'
        optional :visibility, type: String,
                              values: Gitlab::VisibilityLevel.string_values,
                              default: 'internal',
                              desc: 'The visibility of the snippet'
      end
      post do
        authorize! :create_snippet

        attrs = declared_params(include_missing: false).merge(request: request, api: true)
        service_response = ::Snippets::CreateService.new(nil, current_user, attrs).execute
        snippet = service_response.payload[:snippet]

        if service_response.success?
          present snippet, with: Entities::PersonalSnippet
        else
          render_spam_error! if snippet.spam?

          render_api_error!({ error: service_response.message }, service_response.http_status)
        end
      end

      desc 'Update an existing snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
        optional :title, type: String, allow_blank: false, desc: 'The title of a snippet'
        optional :file_name, type: String, desc: 'The name of a snippet file'
        optional :content, type: String, allow_blank: false, desc: 'The content of a snippet'
        optional :description, type: String, desc: 'The description of a snippet'
        optional :visibility, type: String,
                              values: Gitlab::VisibilityLevel.string_values,
                              desc: 'The visibility of the snippet'
        at_least_one_of :title, :file_name, :content, :visibility
      end
      put ':id' do
        snippet = snippets_for_current_user.find_by_id(params.delete(:id))
        break not_found!('Snippet') unless snippet

        authorize! :update_snippet, snippet

        attrs = declared_params(include_missing: false).merge(request: request, api: true)
        service_response = ::Snippets::UpdateService.new(nil, current_user, attrs).execute(snippet)
        snippet = service_response.payload[:snippet]

        if service_response.success?
          present snippet, with: Entities::PersonalSnippet
        else
          render_spam_error! if snippet.spam?

          render_api_error!({ error: service_response.message }, service_response.http_status)
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

        authorize! :admin_snippet, snippet

        destroy_conditionally!(snippet) do |snippet|
          service = ::Snippets::DestroyService.new(current_user, snippet)
          response = service.execute

          if response.error?
            render_api_error!({ error: response.message }, response.http_status)
          end
        end
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
        present content_for(snippet)
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
