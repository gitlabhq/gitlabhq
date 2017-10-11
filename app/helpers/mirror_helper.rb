module MirrorHelper
  def mirror_update_failed?
    return true if @project.hard_failed?

    @project.mirror_last_update_failed?
  end

  def render_mirror_failed_message(status:, icon:)
    message = get_mirror_failed_message(status)

    return message unless icon

    message_with_icon = "#{icon('warning triangle')} #{message}"
    return message_with_icon unless can?(current_user, :admin_project, @project)

    link_to(project_mirror_path(@project)) { "#{icon('warning triangle')} #{message}" }
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

  private

  def get_mirror_failed_message(status)
    if status == :failed
      "The repository failed to update #{time_ago_with_tooltip(@project.last_update_at)}."
    else
      "The repository failed to update #{time_ago_with_tooltip(last_update_at)}.<br>"\
        "Repository mirroring has been paused due to too many failed attempts, and can be resumed by a project admin."
    end
  end
end
