class MattermostSlashCommandsService < SlashCommandsService
  include TriggersHelper

  prop_accessor :token

  def can_test?
    false
  end

  def title
    'Mattermost slash commands'
  end

  def description
    "Perform common operations in Mattermost"
  end

  def self.to_param
    'mattermost_slash_commands'
  end

  def configure(user, params)
    token = Mattermost::Command.new(user)
      .create(command(params))

    update(active: true, token: token) if token
  rescue Mattermost::Error => e
    [false, e.message]
  end

  def list_teams(current_user)
    [Mattermost::Team.new(current_user).all, nil]
  rescue Mattermost::Error => e
    [[], e.message]
  end

  private

  def command(params)
    pretty_project_name = project.full_name

    params.merge(
      auto_complete: true,
      auto_complete_desc: "Perform common operations on: #{pretty_project_name}",
      auto_complete_hint: '[help]',
      description: "Perform common operations on: #{pretty_project_name}",
      display_name: "GitLab / #{pretty_project_name}",
      method: 'P',
      username: 'GitLab')
  end
end
