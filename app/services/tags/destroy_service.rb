# frozen_string_literal: true

module Tags
  class DestroyService < BaseService
    def execute(tag_name)
      repository = project.repository
      tag = repository.find_tag(tag_name)

      unless tag
        return error('No such tag', 404)
      end

      if repository.rm_tag(current_user, tag_name)
        ##
        # When a tag in a repository is destroyed,
        # release assets will be destroyed too.
        Releases::DestroyService
          .new(project, current_user, tag: tag_name)
          .execute

        success('Tag was removed')
      else
        error('Failed to remove tag')
      end
    rescue Gitlab::Git::PreReceiveError => ex
      error(ex.message)
    end

    def error(message, return_code = 400)
      super(message).merge(return_code: return_code)
    end

    def success(message)
      super().merge(message: message)
    end
  end
end
