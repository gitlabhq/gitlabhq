module Team
  def team_member_by_name_or_email(email = nil, name = nil)
    user = users.where("email like ? or name like ?", email, name).first
    users_projects.find_by_user_id(user.id) if user
  end

  def team_member_by_id(user_id)
    users_projects.find_by_user_id(user_id)
  end
end
