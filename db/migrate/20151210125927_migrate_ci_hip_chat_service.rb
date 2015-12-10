class MigrateCiHipChatService < ActiveRecord::Migration
  include Gitlab::Database

  def up
    # From properties strip `hipchat_` key
    properties_query = "SELECT REPLACE(properties, '\"hipchat_', '\"') FROM ci_services " \
      'JOIN ci_projects ON ci_services.project_id=ci_projects.id ' \
      'WHERE ci_projects.gitlab_id=services.project_id'

    active_query = 'SELECT 1 FROM ci_services ' \
      'JOIN ci_projects ON ci_services.project_id=ci_projects.id ' \
      "WHERE ci_projects.gitlab_id=services.project_id AND ci_services.type='Ci::HipchatService' AND ci_services.active"

    # We update the service since services are always generated for project, even if they are inactive
    # Activate service and migrate properties if currently the service is not active
    execute(
      "UPDATE services SET properties=(#{properties_query}), build_events=#{true_value}, active=#{true_value} " \
      "WHERE NOT services.active AND services.type='HipchatService' AND (#{active_query}) IS NOT NULL"
    )

    # Tick only build_events if the service is already active
    execute(
      "UPDATE services SET build_events=#{true_value} " \
      "WHERE services.active AND services.type='HipchatService' AND (#{active_query}) IS NOT NULL"
    )
  end

  def down
  end
end
