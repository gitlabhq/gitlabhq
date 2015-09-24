module CiStatusHelper
  def ci_status_path(ci_commit)
    ci_project_ref_commits_path(ci_commit.project, ci_commit.ref, ci_commit)
  end

  def ci_status_icon(ci_commit)
    icon_name =
      case ci_commit.status
      when 'success'
        'check'
      when 'failed'
        'close'
      when 'running', 'pending'
        'clock-o'
      else
        'circle'
      end

    icon(icon_name)
  end

  def ci_status_color(ci_commit)
    case ci_commit.status
    when 'success'
      'green'
    when 'failed'
      'red'
    when 'running', 'pending'
      'yellow'
    else
      'gray'
    end
  end
end
