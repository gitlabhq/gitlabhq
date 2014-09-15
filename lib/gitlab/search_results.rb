module Gitlab
  class SearchResults
    attr_reader :query

    # Limit search results by passed project ids
    # It allows us to search only for projects user has access to
    attr_reader :limit_project_ids

    def initialize(limit_project_ids, query)
      @limit_project_ids = limit_project_ids || Project.all
      @query = Shellwords.shellescape(query) if query.present?
    end

    def objects(scope, page = nil)
      case scope
      when 'projects'
        projects.page(page).per(per_page)
      when 'issues'
        issues.page(page).per(per_page)
      when 'merge_requests'
        merge_requests.page(page).per(per_page)
      else
        Kaminari.paginate_array([]).page(page).per(per_page)
      end
    end

    def total_count
      @total_count ||= projects_count + issues_count + merge_requests_count
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

    def empty?
      total_count.zero?
    end

    private

    def projects
      Project.where(id: limit_project_ids).search(query)
    end

    def issues
      Issue.where(project_id: limit_project_ids).full_search(query).order('updated_at DESC')
    end

    def merge_requests
      MergeRequest.in_projects(limit_project_ids).full_search(query).order('updated_at DESC')
    end

    def default_scope
      'projects'
    end

    def per_page
      20
    end
  end
end
