require_relative 'base_service'

class CreateTagService < BaseService
  def execute(tag_name, ref, message, release_description = nil)
    valid_tag = Gitlab::GitRefValidator.validate(tag_name)
    if valid_tag == false
      return error('Tag name invalid')
    end

    repository = project.repository
    message.strip! if message
    begin
      new_tag = repository.add_tag(current_user, tag_name, ref, message)
    rescue Rugged::TagError
      return error("Tag #{tag_name} already exists")
    rescue Rugged::ReferenceError
      return error("Target #{ref} is invalid")
    end

    push_data = create_push_data(project, current_user, new_tag)

    EventCreateService.new.push(project, current_user, push_data)
    project.execute_hooks(push_data.dup, :tag_push_hooks)
    project.execute_services(push_data.dup, :tag_push_hooks)
    CreateCommitBuildsService.new.execute(project, current_user, push_data)

    if release_description
      CreateReleaseService.new(@project, @current_user).
        execute(tag_name, release_description)
    end

    success(new_tag)
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
