# frozen_string_literal: true

require 'securerandom'

class AlertsService < Service
  has_one :data, class_name: 'AlertsServiceData', autosave: true,
    inverse_of: :service, foreign_key: :service_id

  attribute :token, :string
  delegate :token, :token=, :token_changed?, :token_was, to: :data

  validates :token, presence: true, if: :activated?

  before_validation :prevent_token_assignment
  before_validation :ensure_token, if: :activated?

  def url
    url_helpers.project_alerts_notify_url(project, format: :json)
  end

  def json_fields
    super + %w(token)
  end

  def editable?
    false
  end

  def show_active_box?
    false
  end

  def can_test?
    false
  end

  def title
    _('Alerts endpoint')
  end

  def description
    _('Receive alerts on GitLab from any source')
  end

  def detailed_description
    description
  end

  def self.to_param
    'alerts'
  end

  def self.supported_events
    %w()
  end

  def data
    super || build_data
  end

  private

  def prevent_token_assignment
    self.token = token_was if token.present? && token_changed?
  end

  def ensure_token
    self.token = generate_token if token.blank?
  end

  def generate_token
    SecureRandom.hex
  end

  def url_helpers
    Gitlab::Routing.url_helpers
  end
end
