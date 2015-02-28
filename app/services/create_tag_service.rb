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
      EventCreateService.new.push_ref(project, current_user, new_tag, 'add', 'refs/tags')

      push_data = create_push_data(project, current_user, new_tag)
      project.execute_hooks(push_data.dup, :tag_push_hooks)
      project.execute_services(push_data.dup, :tag_push_hooks)

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
    data = Gitlab::PushDataBuilder.
      build(project, user, Gitlab::Git::BLANK_SHA, tag.target, 'refs/tags/' + tag.name, [])
    data[:object_kind] = "tag_push"
    data
  end
end
