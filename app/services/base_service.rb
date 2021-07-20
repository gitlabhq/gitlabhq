# frozen_string_literal: true

# This is the original root class for service related classes,
# and due to historical reason takes a project as scope.
# Later separate base classes for different scopes will be created,
# and existing service will use these one by one.
# After all are migrated, we can remove this class.
#
# New services should consider inheriting from:
#
# - BaseContainerService for services scoped by container (project or group)
# - BaseProjectService for services scoped to projects
#
# or, create a new base class and update this comment.
class BaseService
  include BaseServiceUtility
  include Gitlab::Experiment::Dsl

  attr_accessor :project, :current_user, :params

  def initialize(project, user = nil, params = {})
    @project = project
    @current_user = user
    @params = params.dup
  end

  delegate :repository, to: :project
end
