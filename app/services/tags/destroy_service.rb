# frozen_string_literal: true

module Tags
  class DestroyService < BaseService
    def execute(tag_name, skip_find: false)
      repository = project.repository

      # If we've found the tag upstream we don't need to refind it so we can
      # pass skip_find: true
      unless skip_find
        tag = repository.find_tag(tag_name)

        return error('No such tag', 404) unless tag
        return error("You don't have access to delete the tag") unless allowed_to_delete?(tag)
      end

      repository.rm_tag(current_user, tag_name)

      # When a tag in a repository is destroyed, release assets will be
      # destroyed too.
      destroy_releases(tag_name)

      unlock_artifacts(tag_name)

      success('Tag was removed')
    rescue Gitlab::Git::PreReceiveError => ex
      error(ex.message)
    rescue Gitlab::Git::CommandError
      failed_to_remove_tag_error
    end

    def error(message, return_code = 400)
      super(message).merge(return_code: return_code)
    end

    def success(message)
      super().merge(message: message)
    end

    private

    def allowed_to_delete?(tag)
      Ability.allowed?(current_user, :delete_tag, tag)
    end

    def failed_to_remove_tag_error
      error('Failed to remove tag')
    end

    def destroy_releases(tag_name)
      Releases::DestroyService.new(project, current_user, tag: tag_name).execute
    end

    def unlock_artifacts(tag_name)
      Ci::RefDeleteUnlockArtifactsWorker.perform_async(project.id, current_user.id, "#{::Gitlab::Git::TAG_REF_PREFIX}#{tag_name}")
    end
  end
end
