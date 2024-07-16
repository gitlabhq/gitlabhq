# frozen_string_literal: true

# Base class, scoped by container (project or group).
#
# New or existing services which only require a project or group container
# should subclass BaseProjectService or BaseGroupService.
#
# If you require a different but specific, non-polymorphic container
# consider creating a new subclass, and update the related comment at
# the top of the original BaseService.
class BaseContainerService
  include BaseServiceUtility
  include ::Gitlab::Utils::StrongMemoize

  attr_accessor :project, :group
  attr_reader :container, :current_user, :params

  def initialize(container:, current_user: nil, params: {})
    @container = container
    @current_user = current_user
    @params = params.dup

    handle_container_type(container)
  end

  def project_container?
    container.is_a?(::Project)
  end

  def group_container?
    container.is_a?(::Group)
  end

  def namespace_container?
    container.is_a?(::Namespace)
  end

  def project_group
    project&.group
  end
  strong_memoize_attr :project_group

  def root_ancestor
    project_group&.root_ancestor || group&.root_ancestor
  end

  private

  def handle_container_type(container)
    case container
    when Project
      @project = container
    when Group
      @group = container
    when Namespaces::ProjectNamespace
      @project = container.project
    end
  end
end
