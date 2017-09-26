class LdapGroupLink < ActiveRecord::Base
  include Gitlab::Access
  belongs_to :group

  BLANK_ATTRIBUTES = %w[cn filter].freeze

  validates :cn, :group_access, :group_id, presence: true, unless: :filter
  validates :cn, uniqueness: { scope: [:group_id, :provider] }, unless: :filter
  validates :filter, :group_access, :group_id, presence: true, unless: :cn
  validates :filter, uniqueness: { scope: [:group_id, :provider] }, unless: :cn
  validates :filter, ldap_filter: true, if: :filter
  validates :group_access, inclusion: { in: Gitlab::Access.all_values }
  validates :provider, presence: true

  scope :with_provider, ->(provider) { where(provider: provider) }

  before_save :nullify_blank_attributes

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

  private

  def nullify_blank_attributes
    BLANK_ATTRIBUTES.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
