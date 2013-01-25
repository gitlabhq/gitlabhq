module UserTeamsHelper
  def team_filter_path(entity, options={})
    exist_opts = {
      status: params[:status],
      project_id: params[:project_id],
    }

    options = exist_opts.merge(options)

    case entity
    when 'issue' then
      issues_team_path(@team, options)
    when 'merge_request'
      merge_requests_team_path(@team, options)
    end
  end

  def grouped_user_team_members(team)
    team.user_team_user_relationships.sort_by(&:permission).reverse.group_by(&:permission)
  end

  def remove_from_user_team_message(team, member)
    "You are going to remove #{member.name} from #{team.name}. Are you sure?"
  end

end
