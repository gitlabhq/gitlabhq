module MattermostHelper
  def mattermost_teams_options(teams)
    teams.map do |team|
      [team['display_name'] || team['name'], team['id']]
    end
  end
end
