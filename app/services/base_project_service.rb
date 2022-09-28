# frozen_string_literal: true

# Base class, scoped by project
class BaseProjectService < ::BaseContainerService
  include ::Gitlab::Utils::StrongMemoize

  attr_accessor :project

  def initialize(project:, current_user: nil, params: {})
    # we need to exclude project params since they may come from external requests. project should always
    # be passed as part of the service's initializer
    super(container: project, current_user: current_user, params: params.except(:project, :project_id))

    @project = project
  end

  delegate :repository, to: :project

  private

  def project_group
    strong_memoize(:project_group) do
      project.group
    end
  end
end
