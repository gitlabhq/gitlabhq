class ListGcpProjectsService
  def execute(token)
    client = GoogleApi::CloudPlatform::Client.new(token, nil)
    # Lists only projects with billing enabled
    client.projects_list.select do |project|
      begin
        client.projects_get_billing_info(project.project_id).billing_enabled
      rescue
      end
    end
  end
end
