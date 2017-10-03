module MirrorHelper
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
end
