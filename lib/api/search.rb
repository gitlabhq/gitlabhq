# frozen_string_literal: true

module API
  class Search < ::API::Base
    include PaginationParams
    include APIGuard

    before do
      authenticate!

      check_rate_limit!(:search_rate_limit, scope: [current_user],
        users_allowlist: Gitlab::CurrentSettings.current_application_settings.search_rate_limit_allowlist)
    end

    allow_access_with_scope :ai_workflows, if: ->(request) { request.get? || request.head? }

    feature_category :global_search
    urgency :low

    rescue_from ActiveRecord::QueryCanceled do |_e|
      render_api_error!({ error: 'Request timed out' }, 408)
    end

    helpers do
      SCOPE_ENTITY = {
        merge_requests: Entities::MergeRequestBasic,
        issues: Entities::IssueBasic,
        projects: Entities::BasicProjectDetails,
        milestones: Entities::Milestone,
        notes: Entities::Note,
        commits: Entities::CommitDetail,
        blobs: Entities::Blob,
        wiki_blobs: Entities::Blob,
        snippet_titles: Entities::Snippet,
        users: Entities::UserBasic
      }.freeze

      def scope_preload_method
        {
          merge_requests: :with_api_entity_associations,
          projects: :with_api_entity_associations,
          issues: :with_api_entity_associations,
          milestones: :with_api_entity_associations,
          commits: :with_api_commit_entity_associations
        }.freeze
      end

      def search_service(additional_params = {})
        strong_memoize_with(:search_service, additional_params) do
          SearchService.new(current_user, search_params.merge(additional_params))
        end
      end

      def search_params
        {
          scope: params[:scope],
          search: params[:search],
          state: params[:state],
          confidential: params[:confidential],
          snippets: snippets?,
          num_context_lines: params[:num_context_lines],
          search_type: params[:search_type],
          page: params[:page],
          per_page: params[:per_page],
          order_by: params[:order_by],
          sort: params[:sort],
          source: 'api'
        }
      end

      def search(additional_params = {})
        return Kaminari.paginate_array([]) if @project.present? && !project_scope_allowed?

        search_service = search_service(additional_params)
        if search_service.global_search? && !search_service.global_search_enabled_for_scope?
          forbidden!('Global Search is disabled for this scope')
        end

        search_type_errors = search_service.search_type_errors
        bad_request!(search_type_errors) if search_type_errors

        @search_duration_s = Benchmark.realtime do
          @results = search_service.search_objects(preload_method)
        end

        search_results = search_service.search_results
        if search_results.respond_to?(:failed?) && search_results.failed?(search_scope)
          bad_request!(search_results.error(search_scope))
        end

        set_global_search_log_information(additional_params)

        Gitlab::Metrics::GlobalSearchSlis.record_apdex(
          elapsed: @search_duration_s,
          search_type: search_type(additional_params),
          search_level: search_service.level,
          search_scope: search_scope
        )

        Gitlab::InternalEvents.track_event('perform_search', category: 'API::Search', user: current_user)

        paginate(@results)

      ensure
        # If we raise an error somewhere in the @search_duration_s benchmark block, we will end up here
        # with a 200 status code, but an empty @search_duration_s.
        Gitlab::Metrics::GlobalSearchSlis.record_error_rate(
          error: @search_duration_s.nil? || (status < 200 || status >= 400),
          search_type: search_type(additional_params),
          search_level: search_service(additional_params).level,
          search_scope: search_scope
        )
      end

      def project_scope_allowed?
        ::Search::Navigation.new(user: current_user, project: @project).tab_enabled_for_project?(params[:scope].to_sym)
      end

      def snippets?
        %w[snippet_titles].include?(params[:scope]).to_s
      end

      def entity
        SCOPE_ENTITY[params[:scope].to_sym]
      end

      def preload_method
        scope_preload_method[params[:scope].to_sym]
      end

      def verify_search_scope!(resource:)
        # no-op
      end

      def search_type(additional_params = {})
        search_service(additional_params).search_type
      end

      def search_scope
        params[:scope]
      end

      def set_global_search_log_information(additional_params)
        Gitlab::Instrumentation::GlobalSearchApi.set_information(
          type: search_type(additional_params),
          level: search_service(additional_params).level,
          scope: search_scope,
          search_duration_s: @search_duration_s
        )
      end

      def set_headers(additional = {})
        header['X-Search-Type'] = search_type

        additional.each do |key, value|
          header[key] = value
        end
      end

      params :search_params_ee do
        # Overriden in EE
      end
    end

    # rubocop: disable Cop/InjectEnterpriseEditionModule -- params helper needs to be included before the endpoints
    ::API::Search.prepend_mod_with('API::Search')
    # rubocop: enable Cop/InjectEnterpriseEditionModule

    resource :search do
      desc 'Search on GitLab' do
        detail 'This feature was introduced in GitLab 10.5.'
      end
      params do
        requires :search, type: String, desc: 'The expression it should be searched for'
        requires :scope,
          type: String,
          desc: 'The scope of the search',
          values: Helpers::SearchHelpers.global_search_scopes
        optional :state, type: String, desc: 'Filter results by state', values: Helpers::SearchHelpers.search_states
        optional :confidential, type: Boolean, desc: 'Filter results by confidentiality'
        use :search_params_ee
        use :pagination
      end
      get do
        verify_search_scope!(resource: nil)

        set_headers('Content-Transfer-Encoding' => 'binary')

        present search, with: entity, current_user: current_user
      end
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Search on GitLab' do
        detail 'This feature was introduced in GitLab 10.5.'
      end
      params do
        requires :id, type: String, desc: 'The ID of a group'
        requires :search, type: String, desc: 'The expression it should be searched for'
        requires :scope,
          type: String,
          desc: 'The scope of the search',
          values: Helpers::SearchHelpers.group_search_scopes
        optional :state, type: String, desc: 'Filter results by state', values: Helpers::SearchHelpers.search_states
        optional :confidential, type: Boolean, desc: 'Filter results by confidentiality'
        use :search_params_ee
        use :pagination
      end
      get ':id/(-/)search' do
        verify_search_scope!(resource: user_group)

        set_headers

        present search(group_id: user_group.id), with: entity, current_user: current_user
      end
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Search on GitLab' do
        detail 'This feature was introduced in GitLab 10.5.'
      end
      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        requires :search, type: String, desc: 'The expression it should be searched for'
        requires :scope,
          type: String,
          desc: 'The scope of the search',
          values: Helpers::SearchHelpers.project_search_scopes
        optional :ref, type: String,
          desc: 'The name of a repository branch or tag. If not given, the default branch is used'
        optional :state, type: String, desc: 'Filter results by state', values: Helpers::SearchHelpers.search_states
        optional :confidential, type: Boolean, desc: 'Filter results by confidentiality'
        use :search_params_ee
        use :pagination
      end
      get ':id/(-/)search' do
        set_headers

        present search({ project_id: user_project.id, repository_ref: params[:ref] }), with: entity,
          current_user: current_user
      end
    end
  end
end
