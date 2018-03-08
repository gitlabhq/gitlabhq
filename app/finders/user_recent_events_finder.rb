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

  LIMIT = 20

  def initialize(current_user, target_user, params = {})
    @current_user = current_user
    @target_user = target_user
    @params = params
  end

  def execute
    recent_events(params[:offset] || 0)
      .joins(:project)
      .with_associations
      .limit_recent(LIMIT, params[:offset])
  end

  private

  def recent_events(offset)
    sql = <<~SQL
      (#{projects}) AS projects_for_join
      JOIN (#{target_events.to_sql}) AS #{Event.table_name}
        ON #{Event.table_name}.project_id = projects_for_join.id
    SQL

    # Workaround for https://github.com/rails/rails/issues/24193
    Event.from([Arel.sql(sql)])
  end

  def target_events
    Event.where(author: target_user)
  end

  def projects
    # Compile a list of projects `current_user` interacted with
    # and `target_user` is allowed to see.

    authorized = target_user
      .project_interactions
      .joins(:project_authorizations)
      .where(project_authorizations: { user: current_user })
      .select(:id)

    visible = target_user
      .project_interactions
      .where(visibility_level: [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC])
      .select(:id)

    Gitlab::SQL::Union.new([authorized, visible]).to_sql
  end
end
