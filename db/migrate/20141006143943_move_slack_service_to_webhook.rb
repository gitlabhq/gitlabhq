# rubocop:disable all
class MoveSlackServiceToWebhook < ActiveRecord::Migration

  DOWNTIME = true
  DOWNTIME_REASON = 'Move old fields "token" and "subdomain" to one single field "webhook"'

  def change
    SlackService.all.each do |slack_service|
      if ["token", "subdomain"].all? { |property| slack_service.properties.key? property }
        token = slack_service.properties['token']
        subdomain = slack_service.properties['subdomain']
        webhook = "https://#{subdomain}.slack.com/services/hooks/incoming-webhook?token=#{token}"
        slack_service.properties['webhook'] = webhook
        slack_service.properties.delete('token')
        slack_service.properties.delete('subdomain')
        # Room is configured on the Slack side
        slack_service.properties.delete('room')
        slack_service.save(validate: false)
      end
    end
  end
end
