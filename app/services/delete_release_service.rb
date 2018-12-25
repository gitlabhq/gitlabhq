# frozen_string_literal: true

class DeleteReleaseService < BaseService
  include Gitlab::Utils::StrongMemoize

  def execute
    return error('Tag does not exist', 404) unless existing_tag
    return error('Release does not exist', 404) unless release
    return error('Access Denied', 403) unless allowed?

    if release.destory
      success(release: release)
    else
      error(release.errors.messages || '400 Bad request', 400)
    end
  end

  private

  def allowed?
    Ability.allowed?(current_user, :admin_release, release)
  end

  def release
    strong_memoize(:release) do
      project.releases.find_by_tag(@tag_name)
    end
  end

  def existing_tag
    strong_memoize(:existing_tag) do
      repository.find_tag(@tag_name)
    end
  end

  def repository
    strong_memoize(:repository) do
      project.repository
    end
  end  
end
