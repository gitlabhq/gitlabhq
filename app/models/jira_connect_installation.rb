# frozen_string_literal: true

class JiraConnectInstallation < ApplicationRecord
  attr_encrypted :shared_secret,
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key:       Settings.attr_encrypted_db_key_base_32

  has_many :subscriptions, class_name: 'JiraConnectSubscription'

  validates :client_key, presence: true, uniqueness: true
  validates :shared_secret, presence: true
  validates :base_url, presence: true, public_url: true

  scope :for_project, -> (project) {
    distinct
      .joins(:subscriptions)
      .where(jira_connect_subscriptions: {
        id: JiraConnectSubscription.for_project(project)
      })
  }

  def client
    Atlassian::JiraConnect::Client.new(base_url, shared_secret)
  end
end
