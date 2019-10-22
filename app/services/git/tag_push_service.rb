# frozen_string_literal: true

module Git
  class TagPushService < ::BaseService
    include ChangeParams

    def execute
      return unless Gitlab::Git.tag_ref?(ref)

      project.repository.before_push_tag
      TagHooksService.new(project, current_user, params).execute

      true
    end
  end
end
