require_relative 'base_service'

class DeleteTagService < BaseService
  def execute(tag_name)
    repository = project.repository
    tag = repository.find_tag(tag_name)

    # No such tag
    unless tag
      return error('No such tag', 404)
    end

    # Dont allow user to remove tag if he is not allowed to push
    unless current_user.can?(:push_code, project)
      return error('You dont have push access to repo', 405)
    end

    if repository.rm_tag(tag_name)

      # generate push data
      @push_data = create_push_data(project, current_user, tag)

      # notify composer service
      if project.composer_service && project.composer_service.active
        project.composer_service.async_execute(@push_data.dup)
      end

      Event.create_ref_event(project, current_user, tag, 'rm', 'refs/tags')
      success('Branch was removed')
    else
      return error('Failed to remove tag')
    end
  end

  def error(message, return_code = 400)
    out = super(message)
    out[:return_code] = return_code
    out
  end

  def success(message)
    out = super()
    out[:message] = message
    out
  end

  def create_push_data(project, user, tag)
    Gitlab::PushDataBuilder.
      build(project, user, tag.target, Gitlab::Git::BLANK_SHA, 'refs/tags/' + tag.name, [])
  end

end
