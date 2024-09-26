# frozen_string_literal: true

module Tags
  class DestroyService < BaseService
    def execute(tag_name, skip_find: false)
      repository = project.repository

      # If we've found the tag upstream we don't need to refind it so we can
      # pass skip_find: true
      return error('No such tag', 404) unless skip_find || tag_exists?(tag_name)

      if repository.rm_tag(current_user, tag_name)
        # When a tag in a repository is destroyed, release assets will be
        # destroyed too.
        destroy_releases(tag_name)

        unlock_artifacts(tag_name)

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

    private

    def tag_exists?(tag_name)
      repository.find_tag(tag_name)
    end

    def destroy_releases(tag_name)
      Releases::DestroyService.new(project, current_user, tag: tag_name).execute
    end

    def unlock_artifacts(tag_name)
      Ci::RefDeleteUnlockArtifactsWorker.perform_async(project.id, current_user.id, "#{::Gitlab::Git::TAG_REF_PREFIX}#{tag_name}")
    end
  end
end
