# frozen_string_literal: true

module Releases
  class DestroyService < Releases::BaseService
    def execute
      return error('Release does not exist', 404) unless release
      return error('Access Denied', 403) unless allowed?

      track_protected_tag_access_error!

      if release.destroy
        success(tag: existing_tag, release: release)
      else
        error(release.errors.messages || '400 Bad request', 400)
      end
    end

    private

    def allowed?
      Ability.allowed?(current_user, :destroy_release, release)
    end
  end
end
