# frozen_string_literal: true

class ReleasesFinder
  attr_reader :project, :current_user, :params

  def initialize(project, current_user = nil, params = {})
    @project = project
    @current_user = current_user
    @params = params
  end

  def execute(preload: true)
    return Release.none unless Ability.allowed?(current_user, :read_release, project)

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/211988
    releases = project.releases.where.not(tag: nil) # rubocop:disable CodeReuse/ActiveRecord
    releases = by_tag(releases)
    releases = releases.preloaded if preload
    releases.sorted
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def by_tag(releases)
    return releases unless params[:tag].present?

    releases.where(tag: params[:tag])
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
