module Gitlab
  class SearchResults
    class FoundBlob
      include EncodingHelper

      attr_reader :id, :filename, :basename, :ref, :startline, :data, :project_id

      def initialize(opts = {})
        @id = opts.fetch(:id, nil)
        @filename = encode_utf8(opts.fetch(:filename, nil))
        @basename = encode_utf8(opts.fetch(:basename, nil))
        @ref = opts.fetch(:ref, nil)
        @startline = opts.fetch(:startline, nil)
        @data = encode_utf8(opts.fetch(:data, nil))
        @per_page = opts.fetch(:per_page, 20)
        @project_id = opts.fetch(:project_id, nil)
      end

      def path
        filename
      end

      def no_highlighting?
        false
      end
    end

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
                     projects.page(page).per(per_page)
                   when 'issues'
                     issues.page(page).per(per_page)
                   when 'merge_requests'
                     merge_requests.page(page).per(per_page)
                   when 'milestones'
                     milestones.page(page).per(per_page)
                   else
                     Kaminari.paginate_array([]).page(page).per(per_page)
                   end

      without_count ? collection.without_count : collection
    end

    def limited_projects_count
      @limited_projects_count ||= projects.limit(count_limit).count
    end

    def limited_issues_count
      return @limited_issues_count if @limited_issues_count

      # By default getting limited count (e.g. 1000+) is fast on issuable
      # collections except for issues, where filtering both not confidential
      # and confidential issues user has access to, is too complex.
      # It's faster to try to fetch all public issues first, then only
      # if necessary try to fetch all issues.
      sum = issues(public_only: true).limit(count_limit).count
      @limited_issues_count = sum < count_limit ? issues.limit(count_limit).count : sum
    end

    def limited_merge_requests_count
      @limited_merge_requests_count ||= merge_requests.limit(count_limit).count
    end

    def limited_milestones_count
      @limited_milestones_count ||= milestones.limit(count_limit).count
    end

    def single_commit_result?
      false
    end

    def count_limit
      1001
    end

    private

    def projects
      limit_projects.search(query)
    end

    def issues(finder_params = {})
      issues = IssuesFinder.new(current_user, finder_params).execute
      unless default_project_filter
        issues = issues.where(project_id: project_ids_relation)
      end

      issues =
        if query =~ /#(\d+)\z/
          issues.where(iid: $1)
        else
          issues.full_search(query)
        end

      issues.reorder('updated_at DESC')
    end

    def milestones
      milestones = Milestone.where(project_id: project_ids_relation)
      milestones = milestones.search(query)
      milestones.reorder('updated_at DESC')
    end

    def merge_requests
      merge_requests = MergeRequestsFinder.new(current_user).execute
      unless default_project_filter
        merge_requests = merge_requests.in_projects(project_ids_relation)
      end

      merge_requests =
        if query =~ /[#!](\d+)\z/
          merge_requests.where(iid: $1)
        else
          merge_requests.full_search(query)
        end

      merge_requests.reorder('updated_at DESC')
    end

    def default_scope
      'projects'
    end

    def project_ids_relation
      limit_projects.select(:id).reorder(nil)
    end
  end
end
