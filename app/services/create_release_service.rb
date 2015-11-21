require_relative 'base_service'

class CreateReleaseService < BaseService
  def execute(tag_name, release_description)

    repository = project.repository
    existing_tag = repository.find_tag(tag_name)

    # Only create a release if the tag exists
    if existing_tag
      release = project.releases.find_or_initialize_by(tag: tag_name)
      release.update_attributes(description: release_description)

      success(release)
    else
      error('Tag does not exist')
    end
  end

  def success(release)
    out = super()
    out[:release] = release
    out
  end
end
