module Gitlab
  class SearchResults
    attr_reader :current_user, :query

    # Limit search results by passed projects
    # It allows us to search only for projects user has access to
    attr_reader :limit_projects

    def initialize(current_user, limit_projects, query)
      @current_user = current_user
      @limit_projects = limit_projects || Project.all
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

    private

    def projects
      limit_projects.search(query)
    end

    def issues
      issues = IssuesFinder.new(current_user).execute.where(project_id: project_ids_relation)

      if query =~ /#(\d+)\z/
        issues = issues.where(iid: $1)
      else
        issues = issues.full_search(query)
      end

      issues.order('updated_at DESC')
    end

    def milestones
      milestones = Milestone.where(project_id: project_ids_relation)
      milestones = milestones.search(query)
      milestones.order('updated_at DESC')
    end

    def merge_requests
      merge_requests = MergeRequest.in_projects(project_ids_relation)
      if query =~ /[#!](\d+)\z/
        merge_requests = merge_requests.where(iid: $1)
      else
        merge_requests = merge_requests.full_search(query)
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
