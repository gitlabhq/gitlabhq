require_relative 'base_service'

class CreateTagService < BaseService
  def execute(tag_name, target, message, release_description = nil)
    valid_tag = Gitlab::GitRefValidator.validate(tag_name)
    return error('Tag name invalid') unless valid_tag

    repository = project.repository
    message.strip! if message

    new_tag = nil

    begin
      new_tag = repository.add_tag(current_user, tag_name, target, message)
    rescue Rugged::TagError
      return error("Tag #{tag_name} already exists")
    rescue GitHooksService::PreReceiveError => ex
      return error(ex.message)
    end

    if new_tag
      if release_description
        CreateReleaseService.new(@project, @current_user).
          execute(tag_name, release_description)
      end
      
      success.merge(tag: new_tag)
    else
      error("Target #{target} is invalid")
    end
  end
end
