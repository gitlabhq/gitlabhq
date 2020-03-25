# frozen_string_literal: true

class ReleasesFinder
  def initialize(project, current_user = nil)
    @project = project
    @current_user = current_user
  end

  def execute(preload: true)
    return Release.none unless Ability.allowed?(@current_user, :read_release, @project)

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/211988
    releases = @project.releases.where.not(tag: nil) # rubocop:disable CodeReuse/ActiveRecord
    releases = releases.preloaded if preload
    releases.sorted
  end
end
