require_relative 'base_service'

class UpdateReleaseService < BaseService
  def execute(tag_name, release_description)

    repository = project.repository
    existing_tag = repository.find_tag(tag_name)

    if existing_tag
      release = project.releases.find_by(tag: tag_name)

      if release
        release.update_attributes(description: release_description)

        success(release)
      else
        error('Release does not exist', 404)
      end
    else
      error('Tag does not exist', 404)
    end
  end

  def success(release)
    out = super()
    out[:release] = release
    out
  end
end
