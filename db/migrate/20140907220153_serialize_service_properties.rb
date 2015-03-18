class SerializeServiceProperties < ActiveRecord::Migration
  def change
    unless column_exists?(:services, :properties)
      add_column :services, :properties, :text
    end

    Service.reset_column_information

    associations =
    {
      AssemblaService:        [:token, :subdomain],
      CampfireService:        [:token, :subdomain, :room],
      EmailsOnPushService:    [:recipients],
      FlowdockService:        [:token],
      GemnasiumService:       [:api_key, :token],
      GitlabCiService:        [:token, :project_url],
      HipchatService:         [:token, :room],
      PivotaltrackerService:  [:token],
      SlackService:           [:subdomain, :token, :room],
      JenkinsService:         [:project_url],
      JiraService:            [:project_url, :username, :password,
                               :api_version, :jira_issue_transition_id],
    }

    Service.find_each(batch_size: 500).each do |service|
      associations[service.type.to_sym].each do |attribute|
        service.send("#{attribute}=", service.attributes[attribute.to_s])
      end

      service.save(validate: false)
    end

    if column_exists?(:services, :project_url)
      remove_column :services, :project_url, :string
      remove_column :services, :subdomain, :string
      remove_column :services, :room, :string
      remove_column :services, :recipients, :text
      remove_column :services, :api_key, :string
      remove_column :services, :token, :string
    end
  end
end
