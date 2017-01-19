module MattermostHelper
  def mattermost_teams_options(teams)
    teams_options = teams.map do |id, options|
      [options['display_name'] || options['name'], id]
    end

    teams_options.compact.unshift(['Select team...', '0'])
  end
end
