class MigrateCiSlackService < ActiveRecord::Migration
  include Gitlab::Database

  def up
    properties_query = 'SELECT properties FROM ci_services ' \
      'JOIN ci_projects ON ci_services.project_id=ci_projects.id ' \
      "WHERE ci_projects.gitlab_id=services.project_id AND ci_services.type='Ci::SlackService' AND ci_services.active " \
      'LIMIT 1'

    active_query = 'SELECT 1 FROM ci_services ' \
      'JOIN ci_projects ON ci_services.project_id=ci_projects.id ' \
      "WHERE ci_projects.gitlab_id=services.project_id AND ci_services.type='Ci::SlackService' AND ci_services.active " \
      'LIMIT 1'

    # We update the service since services are always generated for project, even if they are inactive
    # Activate service and migrate properties if currently the service is not active
    execute(
      "UPDATE services SET properties=(#{properties_query}), active=#{true_value}, " \
      "push_events=#{false_value}, issues_events=#{false_value}, merge_requests_events=#{false_value}, " \
      "tag_push_events=#{false_value}, note_events=#{false_value}, build_events=#{true_value} " \
      "WHERE NOT services.active AND services.type='SlackService' AND (#{active_query}) IS NOT NULL"
    )

    # Tick only build_events if the service is already active
    execute(
      "UPDATE services SET build_events=#{true_value} " \
      "WHERE services.active AND services.type='SlackService' AND (#{active_query}) IS NOT NULL"
    )
  end

  def down
  end
end
