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
      Event.create_ref_event(project, current_user, new_tag, 'add', 'refs/tags')
      return success(new_tag)
    else
      return error('Invalid reference name')
    end
  end

  def success(branch)
    out = super()
    out[:tag] = branch
    out
  end
end
