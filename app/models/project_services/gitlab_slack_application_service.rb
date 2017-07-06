class GitlabSlackApplicationService < Service
  default_value_for :category, 'chat'

  has_one :slack_integration, foreign_key: :service_id

  def self.supported_events
    %w()
  end

  def show_active_box?
    false
  end

  def editable?
    false
  end

  def update_active_status
    update(active: !!slack_integration)
  end

  def can_test?
    false
  end

  def title
    'Slack application'
  end

  def description
    'Use the GitLab Slack application for this project'
  end

  def self.to_param
    'gitlab_slack_application'
  end

  def fields
    []
  end
end
