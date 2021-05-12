# frozen_string_literal: true

# Base class, scoped by project
class BaseProjectService < ::BaseContainerService
  attr_accessor :project

  def initialize(project:, current_user: nil, params: {})
    super(container: project, current_user: current_user, params: params)

    @project = project
  end

  delegate :repository, to: :project
end
