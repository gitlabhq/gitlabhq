# frozen_string_literal: true

class UpdateReleaseService < BaseService
  attr_accessor :tag_name

  def initialize(project, user, tag_name, params)
    super(project, user, params)

    @tag_name = tag_name
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    repository = project.repository
    existing_tag = repository.find_tag(@tag_name)

    if existing_tag
      release = project.releases.find_by(tag: @tag_name)

      if release
        if release.update(params)
          success(release)
        else
          error(release.errors.messages || '400 Bad request', 400)
        end
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
