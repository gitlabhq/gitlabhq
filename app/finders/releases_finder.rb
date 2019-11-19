# frozen_string_literal: true

class ReleasesFinder
  def initialize(project, current_user = nil)
    @project = project
    @current_user = current_user
  end

  def execute(preload: true)
    return Release.none unless Ability.allowed?(@current_user, :read_release, @project)

    releases = @project.releases
    releases = releases.preloaded if preload
    releases.sorted
  end
end
