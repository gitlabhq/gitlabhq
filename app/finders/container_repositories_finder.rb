# frozen_string_literal: true

class ContainerRepositoriesFinder
  # id: group or project id
  # container_type: :group or :project
  def initialize(id:, container_type:)
    @id = id
    @type = container_type.to_sym
  end

  def execute
    if project_type?
      project.container_repositories
    else
      group.container_repositories
    end
  end

  private

  attr_reader :id, :type

  def project_type?
    type == :project
  end

  def project
    Project.find(id)
  end

  def group
    Group.find(id)
  end
end
