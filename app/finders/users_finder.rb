class UsersFinder
  def execute(user_type)
    case user_type
      when "admins"; User.admins
      when "blocked"; User.blocked
      when "wop"; User.without_projects
      else
        User.active
    end
  end
end
