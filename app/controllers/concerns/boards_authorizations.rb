module BoardsAuthorizations
  # Shared authorizations between projects and groups which
  # have different policies.
  def authorize_read_list!
    ability = board.is_group_board? ? :read_group : :read_list

    return render_403 unless action_allowed_for?(board.parent, ability)
  end

  def authorize_read_issue!
    ability = board.is_group_board? ? :read_group : :read_issue

    return render_403 unless action_allowed_for?(board.parent, ability)
  end

  def authorize_update_issue!
    return render_403 unless action_allowed_for?(issue, :admin_issue)
  end

  def authorize_create_issue!
    return render_403 unless action_allowed_for?(board.parent, :admin_issue)
  end

  def action_allowed_for?(resource, ability)
    can?(current_user, ability, resource)
  end
end
