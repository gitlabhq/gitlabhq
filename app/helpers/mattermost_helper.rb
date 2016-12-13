module MattermostHelper
  def mattermost_teams_for(current_user)
    return unless Gitlab.config.mattermost.enabled
    # Hack to make frontend work better
    return [{"id"=>"qz8gdr1fopncueb8n9on8ohk3h", "create_at"=>1479992105904, "update_at"=>1479992105904, "delete_at"=>0, "display_name"=>"chatops", "name"=>"chatops", "email"=>"admin@example.com", "type"=>"O", "company_name"=>"", "allowed_domains"=>"", "invite_id"=>"gthxi47gj7rxtcx6zama63zd1w", "allow_open_invite"=>false}]


    host = Gitlab.config.mattermost.host
    Mattermost::Mattermost.new(host, current_user).with_session do
      Mattermost::Team.all
    end
  end
end
