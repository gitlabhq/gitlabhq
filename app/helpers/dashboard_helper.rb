module DashboardHelper
  def dashboard_filter_path(entity, options={})
    case entity
    when 'issue' then
      dashboard_issues_path(options)
    when 'merge_request'
      dashboard_merge_requests_path(options)
    end
  end
end
