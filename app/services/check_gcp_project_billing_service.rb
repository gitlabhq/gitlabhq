class CheckGcpProjectBillingService
  def execute(token)
    client = GoogleApi::CloudPlatform::Client.new(token, nil)
    client.projects_list.select do |project|
      client.projects_get_billing_info(project.name).billingEnabled
    end
  end
end
