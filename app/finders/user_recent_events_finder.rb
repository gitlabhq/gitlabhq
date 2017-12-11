# Get user activity feed for projects common for a user and a logged in user
#
# - current_user: The user viewing the events
# - user: The user for which to load the events
# - params:
#   - offset: The page of events to return
class UserRecentEventsFinder
  prepend FinderWithCrossProjectAccess
  include FinderMethods

  requires_cross_project_access

  attr_reader :current_user, :target_user, :params

  def initialize(current_user, target_user, params = {})
    @current_user = current_user
    @target_user = target_user
    @params = params
  end

  def execute
    target_user
      .recent_events
      .merge(projects_for_current_user)
      .references(:project)
      .with_associations
      .limit_recent(20, params[:offset])
  end

  def projects_for_current_user
    ProjectsFinder.new(current_user: current_user).execute
  end
end
