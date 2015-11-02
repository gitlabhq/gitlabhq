class SetJiraServiceApiUrl < ActiveRecord::Migration
  # This migration can be performed online without errors, but some Jira API calls may be missed
  # when doing so because api_url is not yet available.

  def build_api_url_from_project_url(project_url, api_version)
    # this is the exact logic previously used to build the Jira API URL from project_url
    server = URI(project_url)
    default_ports = [80, 443].include?(server.port)
    server_url = "#{server.scheme}://#{server.host}"
    server_url.concat(":#{server.port}") unless default_ports
    "#{server_url}/rest/api/#{api_version}"
  end

  def get_api_version_from_api_url(api_url)
    match = /\/rest\/api\/(?<api_version>\w+)$/.match(api_url)
    match && match['api_version']
  end

  def change
    reversible do |dir|
      select_all("SELECT id, properties FROM services WHERE services.type IN ('JiraService')").each do |jira_service|
        id = jira_service["id"]
        properties = JSON.parse(jira_service["properties"])
        properties_was = properties.clone

        dir.up do
          # remove api_version and set api_url
          if properties['api_version'].present? && properties['project_url'].present?
            begin
              properties['api_url'] ||= build_api_url_from_project_url(properties['project_url'], properties['api_version'])
            rescue
              # looks like project_url was not a valid URL. Do nothing.
            end
          end
          properties.delete('api_version') if properties.include?('api_version')
        end

        dir.down do
          # remove api_url and set api_version (default to '2')
          properties['api_version'] ||= get_api_version_from_api_url(properties['api_url']) || '2'
          properties.delete('api_url') if properties.include?('api_url')
        end

        if properties != properties_was
          execute("UPDATE services SET properties = '#{quote_string(properties.to_json)}' WHERE id = #{id}")
        end
      end
    end
  end
end
