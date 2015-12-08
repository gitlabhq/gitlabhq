require_relative 'base_service'

class CreateTagService < BaseService
  def execute(tag_name, ref, message, release_description = nil)
    valid_tag = Gitlab::GitRefValidator.validate(tag_name)
    if valid_tag == false
      return error('Tag name invalid')
    end

    repository = project.repository
    existing_tag = repository.find_tag(tag_name)
    if existing_tag
      return error('Tag already exists')
    end

    message.strip! if message

    repository.add_tag(tag_name, ref, message)
    new_tag = repository.find_tag(tag_name)

    if new_tag
      push_data = create_push_data(project, current_user, new_tag)
      EventCreateService.new.push(project, current_user, push_data)
      project.execute_hooks(push_data.dup, :tag_push_hooks)
      project.execute_services(push_data.dup, :tag_push_hooks)

      if release_description
        CreateReleaseService.new(@project, @current_user).
          execute(tag_name, release_description)
      end

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
    commits = [project.commit(tag.target)].compact
    Gitlab::PushDataBuilder.
      build(project, user, Gitlab::Git::BLANK_SHA, tag.target, "#{Gitlab::Git::TAG_REF_PREFIX}#{tag.name}", commits, tag.message)
  end
end
