module API
  module V3
    class Snippets < Grape::API
      include PaginationParams

      before { authenticate! }

      resource :snippets do
        helpers do
          def snippets_for_current_user
            SnippetsFinder.new(current_user, author: current_user).execute
          end

          def public_snippets
            SnippetsFinder.new(current_user, visibility: Snippet::PUBLIC).execute
          end
        end

        desc 'Get a snippets list for authenticated user' do
          detail 'This feature was introduced in GitLab 8.15.'
          success ::API::Entities::PersonalSnippet
        end
        params do
          use :pagination
        end
        get do
          present paginate(snippets_for_current_user), with: ::API::Entities::PersonalSnippet
        end

        desc 'List all public snippets current_user has access to' do
          detail 'This feature was introduced in GitLab 8.15.'
          success ::API::Entities::PersonalSnippet
        end
        params do
          use :pagination
        end
        get 'public' do
          present paginate(public_snippets), with: ::API::Entities::PersonalSnippet
        end

        desc 'Get a single snippet' do
          detail 'This feature was introduced in GitLab 8.15.'
          success ::API::Entities::PersonalSnippet
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a snippet'
        end
        get ':id' do
          snippet = snippets_for_current_user.find(params[:id])
          present snippet, with: ::API::Entities::PersonalSnippet
        end

        desc 'Create new snippet' do
          detail 'This feature was introduced in GitLab 8.15.'
          success ::API::Entities::PersonalSnippet
        end
        params do
          requires :title, type: String, desc: 'The title of a snippet'
          requires :file_name, type: String, desc: 'The name of a snippet file'
          requires :content, type: String, desc: 'The content of a snippet'
          optional :visibility_level, type: Integer,
                                      values: Gitlab::VisibilityLevel.values,
                                      default: Gitlab::VisibilityLevel::INTERNAL,
                                      desc: 'The visibility level of the snippet'
        end
        post do
          attrs = declared_params(include_missing: false).merge(request: request, api: true)
          snippet = CreateSnippetService.new(nil, current_user, attrs).execute

          if snippet.persisted?
            present snippet, with: ::API::Entities::PersonalSnippet
          else
            render_validation_error!(snippet)
          end
        end

        desc 'Update an existing snippet' do
          detail 'This feature was introduced in GitLab 8.15.'
          success ::API::Entities::PersonalSnippet
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a snippet'
          optional :title, type: String, desc: 'The title of a snippet'
          optional :file_name, type: String, desc: 'The name of a snippet file'
          optional :content, type: String, desc: 'The content of a snippet'
          optional :visibility_level, type: Integer,
                                      values: Gitlab::VisibilityLevel.values,
                                      desc: 'The visibility level of the snippet'
          at_least_one_of :title, :file_name, :content, :visibility_level
        end
        put ':id' do
          snippet = snippets_for_current_user.find_by(id: params.delete(:id))
          return not_found!('Snippet') unless snippet

          authorize! :update_personal_snippet, snippet

          attrs = declared_params(include_missing: false)

          UpdateSnippetService.new(nil, current_user, snippet, attrs).execute

          if snippet.persisted?
            present snippet, with: ::API::Entities::PersonalSnippet
          else
            render_validation_error!(snippet)
          end
        end

        desc 'Remove snippet' do
          detail 'This feature was introduced in GitLab 8.15.'
          success ::API::Entities::PersonalSnippet
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a snippet'
        end
        delete ':id' do
          snippet = snippets_for_current_user.find_by(id: params.delete(:id))
          return not_found!('Snippet') unless snippet

          authorize! :destroy_personal_snippet, snippet
          snippet.destroy
          no_content!
        end

        desc 'Get a raw snippet' do
          detail 'This feature was introduced in GitLab 8.15.'
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a snippet'
        end
        get ":id/raw" do
          snippet = snippets_for_current_user.find_by(id: params.delete(:id))
          return not_found!('Snippet') unless snippet

          env['api.format'] = :txt
          content_type 'text/plain'
          present snippet.content
        end
      end
    end
  end
end
