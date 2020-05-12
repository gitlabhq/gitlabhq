# frozen_string_literal: true

# This is the original root class for service related classes,
# and due to historical reason takes a project as scope.
# Later separate base classes for different scopes will be created,
# and existing service will use these one by one.
# After all are migrated, we can remove this class.
#
# TODO: New services should consider inheriting from
#       BaseContainerService, or create new base class:
#       https://gitlab.com/gitlab-org/gitlab/-/issues/216672
class BaseService
  include BaseServiceUtility

  attr_accessor :project, :current_user, :params

  def initialize(project, user = nil, params = {})
    @project, @current_user, @params = project, user, params.dup
  end

  delegate :repository, to: :project
end
