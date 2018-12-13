# frozen_string_literal: true

class CreateReleaseService < BaseService
  def execute(tag_name, release_description, name: nil, ref: nil)
    repository = project.repository
    tag = repository.find_tag(tag_name)

    if tag.blank? && ref.present?
      result = create_tag(tag_name, ref)
      return result unless result[:status] == :success

      tag = result[:tag]
    end

    if tag.present?
      create_release(tag, name, release_description)
    else
      error('Tag does not exist', 404)
    end
  end

  def success(release)
    super().merge(release: release)
  end

  private

  def create_release(tag, name, description)
    release = project.releases.find_by(tag: tag.name) # rubocop: disable CodeReuse/ActiveRecord

    if release
      error('Release already exists', 409)
    else
      release = project.releases.create!(
        tag: tag.name,
        name: name || tag.name,
        sha: tag.dereferenced_target.sha,
        author: current_user,
        description: description
      )

      success(release)
    end
  end

  def create_tag(tag_name, ref)
    Tags::CreateService.new(project, current_user)
      .execute(tag_name, ref, nil)
  end
end
