# frozen_string_literal: true

module API
  # Snippets API
  class Snippets < ::API::Base
    include PaginationParams

    feature_category :source_code_management
    urgency :low

    before do
      set_current_organization
    end

    helpers do
      def find_snippets(user: current_user, params: {})
        SnippetsFinder.new(user, params).execute
      end

      def snippets_for_current_user
        find_snippets(params: { author: current_user })
      end
    end

    resource :snippets do
      helpers Helpers::SnippetsHelpers
      helpers SpammableActions::CaptchaCheck::RestApiActionsSupport

      desc 'Get a snippets list for an authenticated user' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::Snippet
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[snippets]
        is_array true
      end
      params do
        optional :created_after, type: DateTime, desc: 'Return snippets created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return snippets created before the specified time'

        use :pagination
      end
      get do
        authenticate!

        filter_params = declared_params(include_missing: false).merge(author: current_user)

        present paginate(find_snippets(params: filter_params)), with: Entities::Snippet, current_user: current_user
      end

      desc 'List all public personal snippets current_user has access to' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[snippets]
        is_array true
      end
      params do
        optional :created_after, type: DateTime, desc: 'Return snippets created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return snippets created before the specified time'

        use :pagination
      end
      get 'public' do
        authenticate!

        filter_params = declared_params(include_missing: false).merge(only_personal: true)

        present paginate(find_snippets(user: nil, params: filter_params)), with: Entities::PersonalSnippet, current_user: current_user
      end

      desc 'List all snippets current_user has access to' do
        detail 'This feature was introduced in GitLab 16.3.'
        success Entities::Snippet
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[snippets]
        is_array true
      end
      params do
        optional :created_after, type: DateTime, desc: 'Return snippets created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return snippets created before the specified time'

        use :pagination
        use :optional_list_params_ee
      end
      get 'all' do
        authenticate!

        filter_params = declared_params(include_missing: false).merge(all_available: true)

        present paginate(find_snippets(params: filter_params)), with: Entities::Snippet, current_user: current_user
      end

      desc 'Get a single snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[snippets]
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
      end
      get ':id' do
        snippet = find_snippets.find_by_id(params[:id])

        break not_found!('Snippet') unless snippet

        present snippet, with: Entities::PersonalSnippet, current_user: current_user
      end

      desc 'Create new snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[snippets]
      end
      params do
        requires :title, type: String, allow_blank: false, desc: 'The title of a snippet'
        optional :description, type: String, desc: 'The description of a snippet'
        optional :visibility, type: String,
          values: Gitlab::VisibilityLevel.string_values,
          default: 'internal',
          desc: 'The visibility of the snippet'

        use :create_file_params
      end
      post do
        authenticate!

        authorize! :create_snippet

        attrs = process_create_params(declared_params(include_missing: false)).merge(organization_id: Current.organization_id)
        service_response = ::Snippets::CreateService.new(project: nil, current_user: current_user, params: attrs).execute
        snippet = service_response.payload[:snippet]

        if service_response.success?
          present snippet, with: Entities::PersonalSnippet, current_user: current_user
        else
          with_captcha_check_rest_api(spammable: snippet) do
            render_api_error!({ error: service_response.message }, service_response.http_status)
          end
        end
      end

      desc 'Update an existing snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[snippets]
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
        optional :content, type: String, allow_blank: false, desc: 'The content of a snippet'
        optional :description, type: String, desc: 'The description of a snippet'
        optional :file_name, type: String, desc: 'The name of a snippet file'
        optional :title, type: String, allow_blank: false, desc: 'The title of a snippet'
        optional :visibility, type: String,
          values: Gitlab::VisibilityLevel.string_values,
          desc: 'The visibility of the snippet'

        use :update_file_params
        use :minimum_update_params
      end
      put ':id' do
        authenticate!

        snippet = snippets_for_current_user.find_by_id(params.delete(:id))
        break not_found!('Snippet') unless snippet

        authorize! :update_snippet, snippet

        validate_params_for_multiple_files(snippet)

        attrs = process_update_params(declared_params(include_missing: false))
        service_response = ::Snippets::UpdateService.new(project: nil, current_user: current_user, params: attrs, perform_spam_check: true).execute(snippet)

        snippet = service_response.payload[:snippet]

        if service_response.success?
          present snippet, with: Entities::PersonalSnippet, current_user: current_user
        else
          with_captcha_check_rest_api(spammable: snippet) do
            render_api_error!({ error: service_response.message }, service_response.http_status)
          end
        end
      end

      desc 'Remove snippet' do
        detail 'This feature was introduced in GitLab 8.15.'
        success Entities::PersonalSnippet
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[snippets]
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
      end
      delete ':id' do
        authenticate!

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
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[snippets]
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
      end
      get ":id/raw" do
        snippet = find_snippets.find_by_id(params.delete(:id))
        not_found!('Snippet') unless snippet

        present content_for(snippet)
      end

      desc 'Get raw snippet file contents from the repository' do
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[snippets]
      end
      params do
        use :raw_file_params
      end
      get ":id/files/:ref/:file_path/raw", requirements: { file_path: API::NO_SLASH_URL_PART_REGEX } do
        snippet = find_snippets.find_by_id(params.delete(:id))
        not_found!('Snippet') unless snippet&.repo_exists?

        present file_content_for(snippet)
      end

      desc 'Get the user agent details for a snippet' do
        success Entities::UserAgentDetail
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[snippets]
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a snippet'
      end
      get ":id/user_agent_detail" do
        authenticated_as_admin!

        snippet = Snippet.find(params[:id])

        break not_found!('UserAgentDetail') unless snippet.user_agent_detail

        present snippet.user_agent_detail, with: Entities::UserAgentDetail
      end
    end
  end
end

API::Snippets.prepend_mod_with('API::Snippets')
