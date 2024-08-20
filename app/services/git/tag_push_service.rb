# frozen_string_literal: true

module Git
  class TagPushService < ::BaseService
    include ChangeParams

    def execute
      return unless Gitlab::Git.tag_ref?(ref)

      project.repository.before_push_tag
      TagHooksService.new(project, current_user, params).execute

      destroy_releases
      unlock_artifacts

      true
    end

    private

    def destroy_releases
      return unless removing_tag?

      Releases::DestroyService.new(project, current_user, tag: Gitlab::Git.tag_name(ref)).execute
    end

    def unlock_artifacts
      return unless removing_tag?

      Ci::RefDeleteUnlockArtifactsWorker.perform_async(project.id, current_user.id, ref)
    end

    def removing_tag?
      Gitlab::Git.blank_ref?(newrev)
    end
  end
end
