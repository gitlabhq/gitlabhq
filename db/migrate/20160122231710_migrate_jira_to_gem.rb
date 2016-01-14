class MigrateJiraToGem < ActiveRecord::Migration
  def change
    reversible do |dir|
      select_all("SELECT id, properties FROM services WHERE services.type IN ('JiraService')").each do |service|
        id = service['id']
        properties = JSON.parse(service['properties'])
        properties_was = properties.clone

        dir.up do
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
        end

        dir.down do
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
        end

        # Update changes properties
        if properties != properties_was
          execute("UPDATE services SET properties = '#{quote_string(properties.to_json)}' WHERE id = #{id}")
        end
      end
    end
  end
end
