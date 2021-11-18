# frozen_string_literal: true

# This is the original root class for service related classes,
# and due to historical reason takes a project as scope.
# Later separate base classes for different scopes will be created,
# and existing service will use these one by one.
# After all are migrated, we can remove this class.
#
# For new services, please see https://docs.gitlab.com/ee/development/reusing_abstractions.html#service-classes
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
