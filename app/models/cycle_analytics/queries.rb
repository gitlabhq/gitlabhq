class CycleAnalytics
  class Queries
    def initialize(project)
      @project = project
    end

    def issues(options = {})
      @issues_data ||=
        begin
          issues_query(options).preload(:metrics).map { |issue| { issue: issue } }
        end
    end

    def merge_requests_closing_issues(options = {})
      @merge_requests_closing_issues_data ||=
        begin
          merge_requests_closing_issues = MergeRequestsClosingIssues.where(issue: issues_query(options)).preload(issue: [:metrics], merge_request: [:metrics])

          merge_requests_closing_issues.map do |record|
            { issue: record.issue, merge_request: record.merge_request }
          end
        end
    end

    def issue_first_associated_with_milestone_at
      lambda do |data_point|
        issue = data_point[:issue]
        issue.metrics.first_associated_with_milestone_at if issue.metrics.present?
      end
    end

    def issue_first_added_to_list_label_at
      lambda do |data_point|
        issue = data_point[:issue]
        issue.metrics.first_added_to_board_at if issue.metrics.present?
      end
    end

    def issue_first_mentioned_in_commit_at
      lambda do |data_point|
        issue = data_point[:issue]
        issue.metrics.first_mentioned_in_commit_at if issue.metrics.present?
      end
    end

    def merge_request_merged_at
      lambda do |data_point|
        merge_request = data_point[:merge_request]
        merge_request.metrics.merged_at if merge_request.metrics.present?
      end
    end

    def merge_request_build_started_at
      lambda do |data_point|
        merge_request = data_point[:merge_request]
        merge_request.metrics.latest_build_started_at if merge_request.metrics.present?
      end
    end

    def merge_request_build_finished_at
      lambda do |data_point|
        merge_request = data_point[:merge_request]
        merge_request.metrics.latest_build_finished_at if merge_request.metrics.present?
      end
    end

    def merge_request_deployed_to_production_at
      lambda do |data_point|
        merge_request = data_point[:merge_request]
        merge_request.metrics.first_deployed_to_production_at if merge_request.metrics.present?
      end
    end

    private

    def issues_query(created_after:)
      @project.issues.where("created_at >= ?", created_after)
    end
  end
end
