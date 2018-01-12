module Gitlab
  class SearchResults
    class FoundBlob
      attr_reader :id, :filename, :basename, :ref, :startline, :data

      def initialize(opts = {})
        @id = opts.fetch(:id, nil)
        @filename = opts.fetch(:filename, nil)
        @basename = opts.fetch(:basename, nil)
        @ref = opts.fetch(:ref, nil)
        @startline = opts.fetch(:startline, nil)
        @data = opts.fetch(:data, nil)
      end

      def path
        filename
      end

      def no_highlighting?
        false
      end
    end

    attr_reader :current_user, :query

    # Limit search results by passed projects
    # It allows us to search only for projects user has access to
    attr_reader :limit_projects

    # Whether a custom filter is used to restrict scope of projects.
    # If the default filter (which lists all projects user has access to)
    # is used, we can skip it when filtering merge requests and optimize the
    # query
    attr_reader :default_project_filter

    def initialize(current_user, limit_projects, query, default_project_filter: false)
      @current_user = current_user
      @limit_projects = limit_projects || Project.all
      @query = query
      @default_project_filter = default_project_filter
    end

    def objects(scope, page = nil)
      case scope
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
    end

    def projects_count
      @projects_count ||= projects.count
    end

    def issues_count
      @issues_count ||= issues.count
    end

    def merge_requests_count
      @merge_requests_count ||= merge_requests.count
    end

    def milestones_count
      @milestones_count ||= milestones.count
    end

    def single_commit_result?
      false
    end

    private

    def projects
      limit_projects.search(query)
    end

    def issues
      issues = IssuesFinder.new(current_user).execute
      unless default_project_filter
        issues = issues.where(project_id: project_ids_relation)
      end

      issues =
        if query =~ /#(\d+)\z/
          issues.where(iid: $1)
        else
          issues.full_search(query)
        end

      issues.order('updated_at DESC')
    end

    def milestones
      milestones = Milestone.where(project_id: project_ids_relation)
      milestones = milestones.search(query)
      milestones.order('updated_at DESC')
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

      merge_requests.order('updated_at DESC')
    end

    def default_scope
      'projects'
    end

    def per_page
      20
    end

    def project_ids_relation
      limit_projects.select(:id).reorder(nil)
    end
  end
end
