# frozen_string_literal: true

module Releases
  class DestroyService < Releases::BaseService
    def execute
      return error(_('Release does not exist'), 404) unless release
      return error(_('Access Denied'), 403) unless allowed?

      if release.destroy
        update_catalog_resource!

        execute_hooks(release, 'delete')

        audit(release, action: :deleted)

        success(tag: existing_tag, release: release)
      else
        error(release.errors.messages || '400 Bad request', 400)
      end
    end

    private

    def update_catalog_resource!
      return unless project.catalog_resource

      return unless project.catalog_resource.versions.none?

      project.catalog_resource.update!(state: 'unpublished')
    end

    def allowed?
      Ability.allowed?(current_user, :destroy_release, release)
    end
  end
end
