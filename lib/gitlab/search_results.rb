# frozen_string_literal: true

module Gitlab
  class SearchResults
    COUNT_LIMIT = 1001

    attr_reader :current_user, :query, :per_page

    # Limit search results by passed projects
    # It allows us to search only for projects user has access to
    attr_reader :limit_projects

    # Whether a custom filter is used to restrict scope of projects.
    # If the default filter (which lists all projects user has access to)
    # is used, we can skip it when filtering merge requests and optimize the
    # query
    attr_reader :default_project_filter

    def initialize(current_user, limit_projects, query, default_project_filter: false, per_page: 20)
      @current_user = current_user
      @limit_projects = limit_projects || Project.all
      @query = query
      @default_project_filter = default_project_filter
      @per_page = per_page
    end

    def objects(scope, page = nil, without_count = true)
      collection = case scope
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
                   else
                     Kaminari.paginate_array([])
                   end.page(page).per(per_page)

      without_count ? collection.without_count : collection
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
      sum = limited_count(issues(public_only: true))
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

    def single_commit_result?
      false
    end

    def count_limit
      COUNT_LIMIT
    end

    def users
      return User.none unless Ability.allowed?(current_user, :read_users_list)

      UsersFinder.new(current_user, search: query).execute
    end

    def display_options(_scope)
      {}
    end

    private

    def projects
      limit_projects.search(query)
    end

    def issues(finder_params = {})
      issues = IssuesFinder.new(current_user, issuable_params.merge(finder_params)).execute

      unless default_project_filter
        issues = issues.where(project_id: project_ids_relation) # rubocop: disable CodeReuse/ActiveRecord
      end

      issues
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
        merge_requests = merge_requests.in_projects(project_ids_relation)
      end

      merge_requests
    end

    def default_scope
      'projects'
    end

    # Filter milestones by authorized projects.
    # For performance reasons project_id is being plucked
    # to be used on a smaller query.
    #
    # rubocop: disable CodeReuse/ActiveRecord
    def filter_milestones_by_project(milestones)
      project_ids =
        milestones.where(project_id: project_ids_relation)
          .select(:project_id).distinct
          .pluck(:project_id)

      return Milestone.none if project_ids.nil?

      authorized_project_ids_relation =
        Project.where(id: project_ids).ids_with_milestone_available_for(current_user)

      milestones.where(project_id: authorized_project_ids_relation)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def project_ids_relation
      limit_projects.select(:id).reorder(nil)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def issuable_params
      {}.tap do |params|
        params[:sort] = 'updated_desc'

        if query =~ /#(\d+)\z/
          params[:iids] = $1
        else
          params[:search] = query
        end
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def limited_count(relation)
      relation.reorder(nil).limit(count_limit).size
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
