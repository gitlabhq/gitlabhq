class CheckGcpProjectBillingService
  def execute(token, project_id)
    client = GoogleApi::CloudPlatform::Client.new(token, nil)
    begin
      client.projects_get_billing_info(project_id).billing_enabled
    rescue
    end
  end
end
