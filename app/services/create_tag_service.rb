require_relative 'base_service'

class CreateTagService < BaseService
  def execute(tag_name, ref, message)
    valid_tag = Gitlab::GitRefValidator.validate(tag_name)
    if valid_tag == false
      return error('Tag name invalid')
    end

    repository = project.repository
    existing_tag = repository.find_tag(tag_name)
    if existing_tag
      return error('Tag already exists')
    end

    if message
      message.gsub!(/^\s+|\s+$/, '')
    end

    repository.add_tag(tag_name, ref, message)
    new_tag = repository.find_tag(tag_name)

    if new_tag
      if project.gitlab_ci?
        push_data = create_push_data(project, current_user, new_tag)
        project.gitlab_ci_service.async_execute(push_data)
      end

      EventCreateService.new.push_ref(project, current_user, new_tag, 'add', 'refs/tags')
      success(new_tag)
    else
      error('Invalid reference name')
    end
  end

  def success(branch)
    out = super()
    out[:tag] = branch
    out
  end

  def create_push_data(project, user, tag)
    Gitlab::PushDataBuilder.
      build(project, user, Gitlab::Git::BLANK_SHA, tag.target, 'refs/tags/' + tag.name, [])
  end
end
