# frozen_string_literal: true

class UpdateReleaseService < BaseService
  # rubocop: disable CodeReuse/ActiveRecord
  def execute(tag_name, release_description)
    repository = project.repository
    existing_tag = repository.find_tag(tag_name)

    if existing_tag
      release = project.releases.find_by(tag: tag_name)

      if release
        release.update(description: release_description)

        success(release)
      else
        error('Release does not exist', 404)
      end
    else
      error('Tag does not exist', 404)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def success(release)
    super().merge(release: release)
  end
end
