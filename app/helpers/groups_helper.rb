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

  def remove_user_from_group_message(group, user)
    "You are going to remove #{user.name} from #{group.name} Group. Are you sure?"
  end
end
