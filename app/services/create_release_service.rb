# frozen_string_literal: true

class CreateReleaseService < BaseService
  def execute(ref = nil)
    return error('Unauthorized', 401) unless Ability.allowed?(current_user, :create_release, project)

    tag_result = find_or_create_tag(ref)
    return tag_result if tag_result[:status] != :success

    create_release(tag_result[:tag])
  end

  private

  def find_or_create_tag(ref)
    tag = repository.find_tag(params[:tag])
    return success(tag: tag) if tag
    return error('Tag does not exist', 404) if ref.blank?

    Tags::CreateService.new(project, current_user).execute(params[:tag], ref, nil)
  end

  def create_release(tag)
    release = Release.by_tag(project, tag.name)

    if release
      error('Release already exists', 409)
    else
      create_params = {
        author: current_user,
        name: tag.name,
        sha: tag.dereferenced_target.sha
      }.merge(params)

      release = project.releases.create!(create_params)

      success(tag: tag, release: release)
    end
  end
end
