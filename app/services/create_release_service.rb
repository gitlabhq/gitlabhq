# frozen_string_literal: true

class CreateReleaseService < BaseService
  # rubocop: disable CodeReuse/ActiveRecord
  def execute(tag_name, release_description)
    repository = project.repository
    existing_tag = repository.find_tag(tag_name)

    # Only create a release if the tag exists
    if existing_tag
      release = project.releases.find_by(tag: tag_name)

      if release
        error('Release already exists', 409)
      else
        release = project.releases.new({ tag: tag_name, description: release_description })
        release.save

        success(release)
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
