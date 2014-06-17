class CreateTagService
  def execute(project, tag_name, ref, current_user)
    repository = project.repository
    repository.add_tag(tag_name, ref)
    new_tag = repository.find_tag(tag_name)

    if new_tag
      Event.create_ref_event(project, current_user, new_tag, 'add', 'refs/tags')
    end

    new_tag
  end
end
