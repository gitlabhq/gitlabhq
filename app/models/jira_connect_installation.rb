# frozen_string_literal: true

class JiraConnectInstallation < ApplicationRecord
  include Gitlab::Routing
  include Gitlab::EncryptedAttribute

  attr_encrypted :shared_secret,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-gcm',
    key: :db_key_base_32

  # Forge app system OAuth token, refreshed by the app to call Jira directly.
  # See Atlassian::Forge::SystemTokenClient.
  attr_encrypted :forge_system_token,
    mode: :per_attribute_iv,
    algorithm: 'aes-256-gcm',
    key: :db_key_base_32

  has_many :subscriptions, class_name: 'JiraConnectSubscription'
  belongs_to :organization, class_name: 'Organizations::Organization'

  # Forge installation ARI, the app.installationId claim of a Forge Invocation
  # Token. Pinned to the ARI form: the value is stored verbatim and the Cells
  # claim normalizes by identity, so a bare uuid would be a second key for the
  # same installation. See gitlab-org/cells/topology-service!548 (note_3737179908).
  FORGE_INSTALLATION_XID_REGEX =
    %r{\Aari:cloud:ecosystem::installation/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z}

  validates :client_key, presence: true, unless: :forge?
  validates :client_key, uniqueness: { scope: :organization_id }, allow_nil: true
  validates :shared_secret, presence: true, unless: :forge?
  validates :base_url, presence: true, unless: :forge?
  validates :base_url, public_url: true, allow_blank: true
  validates :display_url, public_url: true, allow_blank: true
  validates :instance_url, public_url: true, allow_blank: true
  # Jira site (cloud) id; not unique, one site can hold several installations.
  validates :cloud_id, length: { maximum: 255 }, allow_blank: true
  validates :forge_installation_xid, format: { with: FORGE_INSTALLATION_XID_REGEX }, allow_blank: true
  validates :forge_installation_xid, uniqueness: true, allow_nil: true
  validates :cloud_id, presence: true, if: :forge?
  # Jira apiBaseUrl that GitLab calls directly with the Forge system token. It and
  # the token stay optional so a row survives the app clearing or rotating them.
  validates :jira_api_base_url, public_url: true, allow_blank: true
  validate :instance_url_parseable_by_uri, if: :instance_url_changed?

  before_validation :normalize_instance_url

  scope :for_project, ->(project) {
    distinct
      .joins(:subscriptions)
      .where(jira_connect_subscriptions: {
        id: JiraConnectSubscription.for_project(project)
      })
  }

  scope :direct_installations, -> { joins(:subscriptions) }
  scope :proxy_installations, -> { where.not(instance_url: nil) }

  def client
    if forge_direct?
      Atlassian::Forge::SystemTokenClient.new(jira_api_base_url, forge_system_token)
    else
      Atlassian::JiraConnect::Client.new(base_url, shared_secret)
    end
  end

  def oauth_authorization_url
    return Gitlab.config.gitlab.url if instance_url.blank?

    instance_url
  end

  def audience_url
    return unless proxy?

    Gitlab::Utils.append_path(instance_url, jira_connect_base_path)
  end

  def audience_installed_event_url
    return unless proxy?

    Gitlab::Utils.append_path(instance_url, jira_connect_events_installed_path)
  end

  def audience_uninstalled_event_url
    return unless proxy?

    Gitlab::Utils.append_path(instance_url, jira_connect_events_uninstalled_path)
  end

  def create_branch_url
    return unless proxy?

    Gitlab::Utils.append_path(instance_url, new_jira_connect_branch_path)
  end

  def proxy?
    instance_url.present?
  end

  # True once the Forge app registered an apiBaseUrl + system token, enabling
  # direct outbound dev-info. See Atlassian::Forge::SystemTokenClient.
  def forge_direct?
    jira_api_base_url.present? && forge_system_token.present?
  end

  # A row can hold neither credential set: #forge? makes the Connect columns
  # optional, and the app can clear or rotate the Forge apiBaseUrl and token.
  # #client would then build a Connect client that raises on the first call.
  def client_configured?
    forge_direct? || (base_url.present? && shared_secret.present?)
  end

  # A native Forge install: an installation id and no Connect credentials. Gates
  # the conditional Connect validations only; #forge_direct? selects the client.
  def forge?
    forge_installation_xid.present? && client_key.blank?
  end

  private

  # Ruby's URI.parse is stricter than Addressable (used by the public_url
  # validator). Downstream code (e.g. atlassian-jwt) calls URI.parse on the
  # instance_url, so reject values that will blow up there. Only runs on
  # change so rows already persisted with a bad value don't fail unrelated
  # updates - runtime use is guarded by ProxyLifecycleEventService.
  def instance_url_parseable_by_uri
    return if instance_url.blank?

    URI.parse(instance_url)
  rescue URI::InvalidURIError
    errors.add(:instance_url, _('must be a valid URL'))
  end

  def normalize_instance_url
    return if instance_url.blank?

    stripped = instance_url.strip
    return if stripped.start_with?('http://', 'https://')
    return if stripped.include?('://')

    # Only prepend https:// when the value starts with a domain-like token (e.g.
    # "gitlab.example.com" or "gitlab.example.com/path"). Values that don't
    # match (e.g. "/path", "not-a-url") are left as-is so the public_url
    # validator surfaces the original input.
    return unless stripped.match?(/\A[a-zA-Z0-9][a-zA-Z0-9-]*\./)

    self.instance_url = "https://#{stripped}"
  end
end
