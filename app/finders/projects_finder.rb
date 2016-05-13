class ProjectsFinder < UnionFinder
  # Used for:
  #   - all projects (Admin)            => :all
  #   - projects I can access           => :authorized
  #   - visible to me or public         => :public_to_user
  def self.execute(current_user = nil, scope: :public_to_user)
    case scope
    when :all
      Project.without_pending_delete
    when :authorized
      return self.execute unless current_user

      current_user.authorized_projects.without_pending_delete
    when :viewable_starred_projects
      current_user.viewable_starred_projects.without_pending_delete
    when :public_to_user
      # #public_to_user(nil) will yield public projects only
      Project.without_pending_delete.public_to_user(current_user)
    end
  end
end
