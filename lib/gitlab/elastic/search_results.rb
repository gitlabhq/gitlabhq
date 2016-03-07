module Gitlab
  module Elastic
    class SearchResults
      attr_reader :current_user, :query

      # Limit search results by passed project ids
      # It allows us to search only for projects user has access to
      attr_reader :limit_project_ids

      def initialize(current_user, limit_project_ids, query)
        @current_user = current_user
        @limit_project_ids = limit_project_ids || Project.all
        @query = Shellwords.shellescape(query) if query.present?
      end

      def objects(scope, page = nil)
        case scope
        when 'projects'
          projects.records.page(page).per(per_page)
        when 'issues'
          issues.records.page(page).per(per_page)
        when 'merge_requests'
          merge_requests.records.page(page).per(per_page)
        when 'milestones'
          milestones.records.page(page).per(per_page)
        else
          Kaminari.paginate_array([])
        end
      end

      def total_count
        @total_count ||= projects_count + issues_count + merge_requests_count + milestones_count
      end

      def projects_count
        @projects_count ||= projects.total_count
      end

      def issues_count
        @issues_count ||= issues.total_count
      end

      def merge_requests_count
        @merge_requests_count ||= merge_requests.total_count
      end

      def milestones_count
        @milestones_count ||= milestones.total_count
      end

      def empty?
        total_count.zero?
      end

      private

      def projects
        opt = {
          pids: limit_project_ids
        }

        @projects = Project.elastic_search(query, options: opt)
      end

      def issues
        opt = {
          project_ids: limit_project_ids,
          current_user: current_user
        }

        Issue.elastic_search(query, options: opt)
      end

      def milestones
        opt = {
          project_ids: limit_project_ids
        }

        Milestone.elastic_search(query, options: opt)
      end

      def merge_requests
        opt = {
          project_ids: limit_project_ids
        }

        MergeRequest.elastic_search(query, options: opt)
      end

      def default_scope
        'projects'
      end

      def per_page
        20
      end
    end
  end
end
