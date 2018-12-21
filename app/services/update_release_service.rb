# frozen_string_literal: true

class UpdateReleaseService < BaseService
  def execute
    return error('Unauthorized', 401) unless Ability.allowed?(current_user, :update_release, project)

    tag_name = params[:tag]
    release = Release.by_tag(project, tag_name)

    return error('Release does not exist', 404) if release.blank?

    if release.update(params)
      success(release: release)
    else
      error(release.errors.messages || '400 Bad request', 400)
    end
  end
end
