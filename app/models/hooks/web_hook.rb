# frozen_string_literal: true

class WebHook < ApplicationRecord
  include Sortable

  attr_encrypted :token,
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key:       Settings.attr_encrypted_db_key_base_32

  attr_encrypted :url,
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key:       Settings.attr_encrypted_db_key_base_32

  has_many :web_hook_logs, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  validates :url, presence: true, public_url: { allow_localhost: lambda(&:allow_local_requests?),
                                                allow_local_network: lambda(&:allow_local_requests?) }

  validates :token, format: { without: /\n/ }
  validates :push_events_branch_filter, branch_filter: true

  # rubocop: disable CodeReuse/ServiceClass
  def execute(data, hook_name)
    WebHookService.new(self, data, hook_name).execute
  end
  # rubocop: enable CodeReuse/ServiceClass

  # rubocop: disable CodeReuse/ServiceClass
  def async_execute(data, hook_name)
    WebHookService.new(self, data, hook_name).async_execute
  end
  # rubocop: enable CodeReuse/ServiceClass

  # Allow urls pointing localhost and the local network
  def allow_local_requests?
    Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
  end
end
