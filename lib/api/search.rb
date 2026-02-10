# frozen_string_literal: true

# rubocop:disable API/DescriptionSuccessResponse -- search api responds with multiple entity types
module API
  class Search < ::API::Base
    include PaginationParams
    include APIGuard
    include ::API::Concerns::McpAccess

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

    before do
      authenticate!

      check_rate_limit!(
        :search_rate_limit,
        scope: [current_user],
        users_allowlist: Gitlab::CurrentSettings.current_application_settings.search_rate_limit_allowlist
      )
    end

    allow_access_with_scope :ai_workflows, if: ->(request) { request.get? || request.head? }
    allow_mcp_access_read

    feature_category :global_search
    urgency :low

    rescue_from ActiveRecord::QueryCanceled do |_e|
      render_api_error!({ error: 'Request timed out' }, 408)
    end

    helpers do
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
        keys = Helpers::SearchHelpers.search_param_keys
        params_hash = keys.filter_map do |key|
          [key, params[key]] if params.key?(key)
        end.to_h
        params_hash[:snippets] = snippets?
        params_hash[:source] = 'api'
        params_hash
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
        if search_results.respond_to?(:failed?) && search_results.failed?(search_service.scope)
          bad_request!(search_results.error(search_service.scope))
        end

        set_global_search_log_information(additional_params)

        Gitlab::Metrics::GlobalSearchSlis.record_apdex(
          elapsed: @search_duration_s,
          search_type: search_type(additional_params),
          search_level: search_service.level,
          search_scope: search_service.scope
        )

        Gitlab::InternalEvents.track_event('perform_search', category: 'API::Search', user: current_user)

        preload_search_associations

        paginate(@results)
      ensure
        # If we raise an error somewhere in the @search_duration_s benchmark block, we will end up here
        # with a 200 status code, but an empty @search_duration_s.
        # Errors record the user requested scope, otherwise the scope executed is recorded

        search_service = search_service(additional_params)
        Gitlab::Metrics::GlobalSearchSlis.record_error_rate(
          error: @search_duration_s.nil? || (status < 200 || status >= 400),
          search_type: search_type(additional_params),
          search_level: search_service.level,
          search_scope: @search_duration_s.nil? ? user_requested_search_scope : search_service.scope
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

      def verify_search_scope_for_ee!(_); end

      def verify_ee_param_regex!(_); end

      def verify_ee_param_exclude_forks!(_); end

      def verify_ee_param_fields!(_); end

      def search_type(additional_params = {})
        @search_type ||= search_service(additional_params).search_type
      end

      def user_requested_search_scope
        params[:scope]
      end

      def set_global_search_log_information(additional_params)
        Gitlab::Instrumentation::GlobalSearchApi.set_information(
          type: search_type(additional_params),
          level: search_service(additional_params).level,
          scope: search_service.scope,
          search_duration_s: @search_duration_s
        )
      end

      def set_headers(additional = {})
        header['X-Search-Type'] = search_type

        additional.each do |key, value|
          header[key] = value
        end
      end

      def preload_search_associations
        return unless entity.respond_to?(:execute_batch_counting)

        entity.execute_batch_counting(@results)
      end

      params :search_params_common do
        optional :state, type: String, desc: 'Filter results by state', values: Helpers::SearchHelpers.search_states
        optional :confidential, type: Boolean, desc: 'Filter results by confidentiality'
      end

      params :search_params_archived_filter do
        optional :include_archived, type: Boolean, default: false,
          desc: 'Includes archived projects in the search. Introduced in GitLab 18.9.'
      end

      params :ee_param_fields do
        # Overridden in EE
      end

      params :ee_param_exclude_forks do
        # Overridden in EE
      end

      params :ee_param_regex do
        # Overridden in EE
      end
    end

    # rubocop: disable Cop/InjectEnterpriseEditionModule -- params helper needs to be included before the endpoints
    ::API::Search.prepend_mod_with('API::Search')
    # rubocop: enable Cop/InjectEnterpriseEditionModule

    resource :search do
      desc 'Search on GitLab' do
        detail 'This feature was introduced in GitLab 10.5.'
        tags ['search']
      end

      params do
        requires :search, type: String, desc: 'The expression it should be searched for'
        requires :scope, type: String, desc: 'The scope of the search',
          values: Helpers::SearchHelpers.global_search_scopes

        use :search_params_common
        use :search_params_archived_filter
        use :ee_param_fields
        use :ee_param_exclude_forks
        use :ee_param_regex
        use :pagination
      end
      route_setting :mcp, tool_name: :gitlab_search_in_instance,
        params: Helpers::SearchHelpers.gitlab_search_mcp_params, aggregators: [::Mcp::Tools::SearchService]
      get do
        verify_search_scope_for_ee!(search_type)
        verify_ee_param_regex!(search_type)
        verify_ee_param_exclude_forks!(search_type)
        verify_ee_param_fields!(search_type)

        set_headers('Content-Transfer-Encoding' => 'binary')

        present search, with: entity, current_user: current_user
      end
    end

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Search on GitLab within a group' do
        detail 'This feature was introduced in GitLab 10.5.'
        tags %w[search]
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the group'
        requires :search, type: String, desc: 'The expression it should be searched for'
        requires :scope, type: String, desc: 'The scope of the search',
          values: Helpers::SearchHelpers.group_search_scopes

        use :search_params_common
        use :search_params_archived_filter
        use :ee_param_fields
        use :ee_param_exclude_forks
        use :ee_param_regex
        use :pagination
      end
      route_setting :mcp, tool_name: :gitlab_search_in_group,
        params: Helpers::SearchHelpers.gitlab_search_mcp_params, aggregators: [::Mcp::Tools::SearchService]
      get ':id/(-/)search' do
        additional_params = { group_id: user_group.id }
        search_type = search_type(additional_params)
        verify_search_scope_for_ee!(search_type)
        verify_ee_param_regex!(search_type)
        verify_ee_param_exclude_forks!(search_type)
        verify_ee_param_fields!(search_type)

        set_headers

        present search(additional_params), with: entity, current_user: current_user
      end
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Search on GitLab within a project' do
        detail 'This feature was introduced in GitLab 10.5.'
        tags %w[search projects]
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        requires :search, type: String, desc: 'The expression it should be searched for'
        requires :scope, type: String, desc: 'The scope of the search',
          values: Helpers::SearchHelpers.project_search_scopes

        optional :ref, type: String,
          desc: 'The name of a repository branch or tag. If not given, the default branch is used'

        use :search_params_common
        use :ee_param_fields
        use :ee_param_regex
        use :pagination
      end
      route_setting :mcp, tool_name: :gitlab_search_in_project,
        params: Helpers::SearchHelpers.gitlab_search_mcp_params, aggregators: [::Mcp::Tools::SearchService]
      get ':id/(-/)search' do
        additional_params = { project_id: user_project.id, repository_ref: params[:ref] }
        search_type = search_type(additional_params)
        verify_ee_param_regex!(search_type)
        verify_ee_param_exclude_forks!(search_type)
        verify_ee_param_fields!(search_type)

        set_headers

        present search(additional_params), with: entity, current_user: current_user
      end
    end
  end
end
# rubocop:enable API/DescriptionSuccessResponse
