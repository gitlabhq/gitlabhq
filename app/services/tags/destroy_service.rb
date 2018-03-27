module Tags
  class DestroyService < BaseService
    def execute(tag_name)
      repository = project.repository
      tag = repository.find_tag(tag_name)

      unless tag
        return error('No such tag', 404)
      end

      if repository.rm_tag(current_user, tag_name)
        release = project.releases.find_by(tag: tag_name)
        release&.destroy

        push_data = build_push_data(tag)
        EventCreateService.new.push(project, current_user, push_data)
        project.execute_hooks(push_data.dup, :tag_push_hooks)
        project.execute_services(push_data.dup, :tag_push_hooks)

        success('Tag was removed')
      else
        error('Failed to remove tag')
      end
    rescue Gitlab::Git::HooksService::PreReceiveError => ex
      error(ex.message)
    end

    def error(message, return_code = 400)
      super(message).merge(return_code: return_code)
    end

    def success(message)
      super().merge(message: message)
    end

    def build_push_data(tag)
      Gitlab::DataBuilder::Push.build(
        project,
        current_user,
        tag.dereferenced_target.sha,
        Gitlab::Git::BLANK_SHA,
        "#{Gitlab::Git::TAG_REF_PREFIX}#{tag.name}",
        [])
    end
  end
end
