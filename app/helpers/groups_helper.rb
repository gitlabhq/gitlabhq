module GroupsHelper
  def group_filter_path(entity, options={})
    exist_opts = {
      status: params[:status],
      project_id: params[:project_id],
    }

    options = exist_opts.merge(options)

    case entity
    when 'issue' then
      issues_group_path(@group, options)
    when 'merge_request'
      merge_requests_group_path(@group, options)
    end
  end
end
