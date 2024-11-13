# frozen_string_literal: true

module Gitlab
  class SearchResults
    COUNT_LIMIT = 100
    COUNT_LIMIT_MESSAGE = "#{COUNT_LIMIT - 1}+".freeze
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 20

    attr_reader :current_user, :query, :order_by, :sort, :filters

    # Limit search results by passed projects
    # It allows us to search only for projects user has access to
    attr_reader :limit_projects

    # Whether a custom filter is used to restrict scope of projects.
    # If the default filter (which lists all projects user has access to)
    # is used, we can skip it when filtering merge requests and optimize the
    # query
    attr_reader :default_project_filter

    def initialize(
      current_user,
      query,
      limit_projects = nil,
      order_by: nil,
      sort: nil,
      default_project_filter: false,
      filters: {})
      @current_user = current_user
      @query = query
      @limit_projects = limit_projects || Project.all
      @default_project_filter = default_project_filter
      @order_by = order_by
      @sort = sort
      @filters = filters
    end

    def objects(scope, page: nil, per_page: DEFAULT_PER_PAGE, without_count: true, preload_method: nil)
      should_preload = preload_method.present?
      collection = collection_for(scope)

      if collection.nil?
        should_preload = false
        collection = Kaminari.paginate_array([])
      end

      collection = collection.public_send(preload_method) if should_preload # rubocop:disable GitlabSecurity/PublicSend
      collection = collection.page(page).per(per_page)

      without_count ? collection.without_count : collection
    end

    def formatted_count(scope)
      case scope
      when 'projects'
        formatted_limited_count(limited_projects_count)
      when 'issues'
        formatted_limited_count(limited_issues_count)
      when 'merge_requests'
        formatted_limited_count(limited_merge_requests_count)
      when 'milestones'
        formatted_limited_count(limited_milestones_count)
      when 'users'
        formatted_limited_count(limited_users_count)
      end
    end

    def formatted_limited_count(count)
      if count >= COUNT_LIMIT
        COUNT_LIMIT_MESSAGE
      else
        count.to_s
      end
    end

    def limited_projects_count
      @limited_projects_count ||= limited_count(projects)
    end

    def limited_issues_count
      return @limited_issues_count if @limited_issues_count

      # By default getting limited count (e.g. 1000+) is fast on issuable
      # collections except for issues, where filtering both not confidential
      # and confidential issues user has access to, is too complex.
      # It's faster to try to fetch all public issues first, then only
      # if necessary try to fetch all issues.
      sum = limited_count(issues(confidential: false))
      @limited_issues_count = sum < count_limit ? limited_count(issues) : sum
    end

    def limited_merge_requests_count
      @limited_merge_requests_count ||= limited_count(merge_requests)
    end

    def limited_milestones_count
      @limited_milestones_count ||= limited_count(milestones)
    end

    def limited_users_count
      @limited_users_count ||= limited_count(users)
    end

    def count_limit
      COUNT_LIMIT
    end

    def users
      return User.none unless Ability.allowed?(current_user, :read_users_list)

      UsersFinder.new(current_user, { search: query, use_minimum_char_limit: false }).execute
    end

    # highlighting is only performed by Elasticsearch backed results
    def highlight_map(*)
      {}
    end

    # aggregations are only performed by Elasticsearch backed results
    def aggregations(*)
      []
    end

    def failed?(*)
      false
    end

    def error(*)
      nil
    end

    private

    def collection_for(scope)
      case scope
      when 'projects'
        projects
      when 'issues'
        issues
      when 'merge_requests'
        merge_requests
      when 'milestones'
        milestones
      when 'users'
        users
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def apply_sort(results, scope: nil)
      # Due to different uses of sort param we prefer order_by when
      # present
      sort_by = ::Gitlab::Search::SortOptions.sort_and_direction(order_by, sort)

      # Reset sort to default if the chosen one is not supported by scope
      if Gitlab::Search::SortOptions::SCOPE_ONLY_SORT[sort_by] &&
          Gitlab::Search::SortOptions::SCOPE_ONLY_SORT[sort_by].exclude?(scope)
        sort_by = nil
      end

      case sort_by
      when :created_at_asc
        results.reorder('created_at ASC')
      when :updated_at_asc
        results.reorder('updated_at ASC')
      when :updated_at_desc
        results.reorder('updated_at DESC')
      when :popularity_asc
        results.reorder('upvotes_count ASC')
      when :popularity_desc
        results.reorder('upvotes_count DESC')
      else
        # :created_at_desc is default
        results.reorder('created_at DESC')
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def projects
      scope = limit_projects
      scope = scope.non_archived unless filters[:include_archived]

      scope.search(query, include_namespace: true, use_minimum_char_limit: false)
    end

    def issues(finder_params = {})
      issues = IssuesFinder.new(current_user, issuable_params.merge(finder_params)).execute
                 .preload(::Gitlab::Issues::TypeAssociationGetter.call) # rubocop: disable CodeReuse/ActiveRecord -- preload for permission checks

      unless default_project_filter
        project_ids = project_ids_relation
        project_ids = project_ids.non_archived unless filters[:include_archived]

        issues = issues.in_projects(project_ids)
                       .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/420046')
      end

      apply_sort(issues, scope: 'issues')
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def milestones
      milestones = Milestone.search(query)

      milestones = filter_milestones_by_project(milestones)

      milestones.reorder('updated_at DESC')
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def merge_requests
      merge_requests = MergeRequestsFinder.new(current_user, issuable_params).execute

      unless default_project_filter
        project_ids = project_ids_relation

        project_ids = project_ids.non_archived unless filters[:include_archived]

        merge_requests = merge_requests.of_projects(project_ids)
      end

      apply_sort(merge_requests, scope: 'merge_requests')
    end

    def default_scope
      'projects'
    end

    # Filter milestones by authorized projects.
    # For performance reasons project_id is being plucked
    # to be used on a smaller query.
    def filter_milestones_by_project(milestones)
      candidate_project_ids = project_ids_relation

      candidate_project_ids = candidate_project_ids.non_archived unless filters[:include_archived]

      project_ids = milestones.of_projects(candidate_project_ids).select(:project_id).distinct.pluck(:project_id) # rubocop: disable CodeReuse/ActiveRecord

      return Milestone.none if project_ids.nil?

      authorized_project_ids_relation = Project.id_in(project_ids).ids_with_issuables_available_for(current_user)

      milestones.of_projects(authorized_project_ids_relation)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def project_ids_relation
      limit_projects.select(:id).reorder(nil)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def issuable_params
      {}.tap do |params|
        params[:sort] = 'updated_desc'

        if query =~ /#(\d+)\z/
          params[:iids] = Regexp.last_match(1)
        else
          params[:search] = query
        end

        params[:state] = filters[:state] if filters.key?(:state)

        params[:confidential] = filters[:confidential] if [true, false].include?(filters[:confidential])
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def limited_count(relation)
      relation.reorder(nil).limit(count_limit).size
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

Gitlab::SearchResults.prepend_mod_with('Gitlab::SearchResults')
