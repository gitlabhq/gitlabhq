# frozen_string_literal: true

class WebHook < ActiveRecord::Base
  include Sortable

  attr_encrypted :token,
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key:       Settings.attr_encrypted_db_key_base_truncated

  attr_encrypted :url,
                 mode:      :per_attribute_iv,
                 algorithm: 'aes-256-gcm',
                 key:       Settings.attr_encrypted_db_key_base_truncated

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
    false
  end

  # In 11.4, the web_hooks table has both `token` and `encrypted_token` fields.
  # Ensure that the encrypted version always takes precedence if present.
  alias_method :attr_encrypted_token, :token
  def token
    attr_encrypted_token.presence || read_attribute(:token)
  end

  # In 11.4, the web_hooks table has both `token` and `encrypted_token` fields.
  # Pending a background migration to encrypt all fields, we should just clear
  # the unencrypted value whenever the new value is set.
  alias_method :'attr_encrypted_token=', :'token='
  def token=(value)
    self.attr_encrypted_token = value

    write_attribute(:token, nil)
  end

  # In 11.4, the web_hooks table has both `url` and `encrypted_url` fields.
  # Ensure that the encrypted version always takes precedence if present.
  alias_method :attr_encrypted_url, :url
  def url
    attr_encrypted_url.presence || read_attribute(:url)
  end

  # In 11.4, the web_hooks table has both `url` and `encrypted_url` fields.
  # Pending a background migration to encrypt all fields, we should just clear
  # the unencrypted value whenever the new value is set.
  alias_method :'attr_encrypted_url=', :'url='
  def url=(value)
    self.attr_encrypted_url = value

    write_attribute(:url, nil)
  end
end
