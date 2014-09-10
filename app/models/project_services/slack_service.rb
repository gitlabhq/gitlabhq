# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  properties  :text
#

class SlackService < Service
  prop_accessor :room, :subdomain, :token
  validates :room, presence: true, if: :activated?
  validates :subdomain, presence: true, if: :activated?
  validates :token, presence: true, if: :activated?

  def title
    'Slack'
  end

  def description
    'A team communication tool for the 21st century'
  end

  def to_param
    'slack'
  end

  def fields
    [
      { type: 'text', name: 'subdomain', placeholder: '' },
      { type: 'text', name: 'token',     placeholder: '' },
      { type: 'text', name: 'room',      placeholder: 'Ex. #general' },
    ]
  end

  def execute(push_data)
    message = SlackMessage.new(push_data.merge(
      project_url: project_url,
      project_name: project_name
    ))

    notifier = Slack::Notifier.new(subdomain, token)
    notifier.channel = room
    notifier.username = 'GitLab'
    notifier.ping(message.pretext, attachments: message.attachments)
  end

  private

  def project_name
    project.name_with_namespace.gsub(/\s/, '')
  end

  def project_url
    project.web_url
  end
end
