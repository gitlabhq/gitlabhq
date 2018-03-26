module MirrorHelper
  def render_mirror_failed_message(raw_message:)
    mirror_last_update_at = @project.mirror_last_update_at
    message = "The repository failed to update #{time_ago_with_tooltip(mirror_last_update_at)}.".html_safe

    return message if raw_message

    message.insert(0, "#{icon('warning triangle')} ")

    if can?(current_user, :admin_project, @project)
      link_to message, project_mirror_path(@project)
    else
      message
    end
  end

  def branch_diverged_tooltip_message
    message = s_('Branches|The branch could not be updated automatically because it has diverged from its upstream counterpart.')

    if can?(current_user, :push_code, @project)
      message << '<br>'
      message << s_("Branches|To discard the local changes and overwrite the branch with the upstream version, delete it here and choose 'Update Now' above.")
    end

    message
  end

  def options_for_mirror_user
    options_from_collection_for_select(default_mirror_users, :id, :name, @project.mirror_user_id || current_user.id)
  end

  def mirror_repositories_count(project = @project)
    count = project.username_only_import_url.present? ? 1 : 0

    count + @project.remote_mirrors.count { |mirror| mirror.safe_url.present? == true }
  end
end
