class LdapGroupLink < ActiveRecord::Base
  include Gitlab::Access
  belongs_to :group

  validates :cn, :group_access, :group_id, presence: true
  validates :cn, uniqueness: { scope: [:group_id, :provider] }
  validates :group_access, inclusion: { in: Gitlab::Access.all_values }
  validates :provider, presence: true

  scope :with_provider, ->(provider) { where(provider: provider) }

  def access_field
    group_access
  end

  def config
    Gitlab::LDAP::Config.new(provider)
  rescue Gitlab::LDAP::Config::InvalidProvider
    nil
  end

  # default to the first LDAP server
  def provider
    read_attribute(:provider) || Gitlab::LDAP::Config.providers.first
  end

  def provider_label
    config.label
  end
end
