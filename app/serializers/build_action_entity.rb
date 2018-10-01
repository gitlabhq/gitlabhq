# frozen_string_literal: true

class BuildActionEntity < Grape::Entity
  include RequestAwareEntity

  expose :name do |build|
    build.name
  end

  expose :path do |build|
    play_project_job_path(build.project, build)
  end

  expose :playable?, as: :playable
  expose :scheduled_at, if: -> (build) { build.scheduled? }

  expose :unschedule_path, if: -> (build) { build.scheduled? } do |build|
    unschedule_project_job_path(build.project, build)
  end

  private

  alias_method :build, :object

  def playable?
    build.playable? && can?(request.current_user, :update_build, build)
  end
end
