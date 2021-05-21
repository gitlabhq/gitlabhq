# frozen_string_literal: true

# Base class, scoped by container (project or group).
#
# New or existing services which only require project as a container
# should subclass BaseProjectService.
#
# If you require a different but specific, non-polymorphic container (such
# as group), consider creating a new subclass such as BaseGroupService,
# and update the related comment at the top of the original BaseService.
class BaseContainerService
  include BaseServiceUtility

  attr_reader :container, :current_user, :params

  def initialize(container:, current_user: nil, params: {})
    @container = container
    @current_user = current_user
    @params = params.dup
  end

  def project_container?
    container.is_a?(::Project)
  end

  def group_container?
    container.is_a?(::Group)
  end
end
