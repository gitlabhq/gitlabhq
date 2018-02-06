class MigrateJiraToGem < ActiveRecord::Migration
  DOWNTIME = true

  DOWNTIME_REASON = <<-HEREDOC
    Refactor all Jira services properties(serialized field) to use new jira-ruby gem.
    There were properties on old Jira service that are not needed anymore after the
    service refactoring: api_url, project_url, new_issue_url, issues_url.
    We extract the new necessary some properties from old keys and delete them:
    taking project_key from project_url and url from api_url
  HEREDOC

  def up
    active_services_query = "SELECT id, properties FROM services WHERE services.type IN ('JiraService') AND services.active = true"

    select_all(active_services_query).each do |service|
      id = service['id']
      properties = JSON.parse(service['properties'])
      properties_was = properties.clone

      # Migrate `project_url` to `project_key`
      # Ignore if `project_url` doesn't have jql project query with project key
      if properties['project_url'].present?
        jql = properties['project_url'].match('project=([A-Za-z]*)')
        properties['project_key'] = jql.captures.first if jql
      end

      # Migrate `api_url` to `url`
      if properties['api_url'].present?
        url = properties['api_url'].match('(.*)\/rest\/api')
        properties['url'] = url.captures.first if url
      end

      # Delete now unnecessary properties
      properties.delete('api_url')
      properties.delete('project_url')
      properties.delete('new_issue_url')
      properties.delete('issues_url')

      # Update changes properties
      if properties != properties_was
        execute("UPDATE services SET properties = '#{quote_string(properties.to_json)}' WHERE id = #{id}")
      end
    end
  end

  def down
    active_services_query = "SELECT id, properties FROM services WHERE services.type IN ('JiraService') AND services.active = true"

    select_all(active_services_query).each do |service|
      id = service['id']
      properties = JSON.parse(service['properties'])
      properties_was = properties.clone

      # Rebuild old properties based on sane defaults
      if properties['url'].present?
        properties['api_url'] = "#{properties['url']}/rest/api/2"
        properties['project_url'] =
          "#{properties['url']}/issues/?jql=project=#{properties['project_key']}"
        properties['issues_url'] = "#{properties['url']}/browse/:id"
        properties['new_issue_url'] = "#{properties['url']}/secure/CreateIssue.jspa"
      end

      # Delete the new properties
      properties.delete('url')
      properties.delete('project_key')

      # Update changes properties
      if properties != properties_was
        execute("UPDATE services SET properties = '#{quote_string(properties.to_json)}' WHERE id = #{id}")
      end
    end
  end
end
