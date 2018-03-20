module API
  class Search < Grape::API
    include PaginationParams

    before { authenticate! }

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
        snippet_blobs: Entities::Snippet
      }.freeze

      ELASTICSEARCH_SCOPES = %w(wiki_blobs blobs commits).freeze

      def search(additional_params = {})
        search_params = {
          scope: params[:scope],
          search: params[:search],
          snippets: snippets?,
          page: params[:page],
          per_page: params[:per_page]
        }.merge(additional_params)

        results = SearchService.new(current_user, search_params).search_objects

        process_results(results)
      end

      def process_results(results)
        return [] if results.empty?

        if results.is_a?(Elasticsearch::Model::Response::Response)
          return paginate(results).map { |blob| Gitlab::Elastic::SearchResults.parse_search_result(blob) }
        end

        case params[:scope]
        when 'wiki_blobs'
          paginate(results).map { |blob| Gitlab::ProjectSearchResults.parse_search_result(blob, user_project) }
        when 'blobs'
          paginate(results).map { |blob| blob[1] }
        else
          paginate(results)
        end
      end

      def snippets?
        %w(snippet_blobs snippet_titles).include?(params[:scope]).to_s
      end

      def entity
        SCOPE_ENTITY[params[:scope].to_sym]
      end

      def check_elasticsearch_scope!
        if ELASTICSEARCH_SCOPES.include?(params[:scope]) && !elasticsearch?
          render_api_error!({ error: 'Scope not supported without Elasticsearch!' }, 400)
        end
      end

      def elasticsearch?
        Gitlab::CurrentSettings.elasticsearch_search?
      end
    end

    resource :search do
      desc 'Search on GitLab' do
        detail 'This feature was introduced in GitLab 10.5.'
      end
      params do
        requires :search, type: String, desc: 'The expression it should be searched for'
        requires :scope,
          type: String,
          desc: 'The scope of search, available scopes:
            projects, issues, merge_requests, milestones, snippet_titles, snippet_blobs,
            if Elasticsearch enabled: wiki_blobs, blobs, commits',
          values: %w(projects issues merge_requests milestones snippet_titles snippet_blobs
                     wiki_blobs blobs commits)
        use :pagination
      end
      get do
        check_elasticsearch_scope!

        present search, with: entity
      end
    end

    resource :groups, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Search on GitLab' do
        detail 'This feature was introduced in GitLab 10.5.'
      end
      params do
        requires :id, type: String, desc: 'The ID of a group'
        requires :search, type: String, desc: 'The expression it should be searched for'
        requires :scope,
          type: String,
          desc: 'The scope of search, available scopes:
            projects, issues, merge_requests, milestones,
            if Elasticsearch enabled: wiki_blobs, blobs, commits',
          values: %w(projects issues merge_requests milestones wiki_blobs blobs commits)
        use :pagination
      end
      get ':id/(-/)search' do
        check_elasticsearch_scope!

        present search(group_id: user_group.id), with: entity
      end
    end

    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Search on GitLab' do
        detail 'This feature was introduced in GitLab 10.5.'
      end
      params do
        requires :id, type: String, desc: 'The ID of a project'
        requires :search, type: String, desc: 'The expression it should be searched for'
        requires :scope,
          type: String,
          desc: 'The scope of search, available scopes:
            issues, merge_requests, milestones, notes, wiki_blobs, commits, blobs',
          values: %w(issues merge_requests milestones notes wiki_blobs commits blobs)
        use :pagination
      end
      get ':id/(-/)search' do
        present search(project_id: user_project.id), with: entity
      end
    end
  end
end
