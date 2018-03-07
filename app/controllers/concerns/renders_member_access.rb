module RendersMemberAccess
  def prepare_groups_for_rendering(groups)
    preload_max_member_access_for_collection(Group, groups)

    groups
  end

  def prepare_projects_for_rendering(projects)
    preload_max_member_access_for_collection(Project, projects)

    projects
  end

  private

  def preload_max_member_access_for_collection(klass, collection)
    return if !current_user || collection.blank?

    method_name = "max_member_access_for_#{klass.name.underscore}_ids"

    current_user.public_send(method_name, collection.ids) # rubocop:disable GitlabSecurity/PublicSend
  end
end
