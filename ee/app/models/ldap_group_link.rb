class LdapGroupLink < ActiveRecord::Base
  include Gitlab::Access
  belongs_to :group

  BLANK_ATTRIBUTES = %w[cn filter].freeze

  with_options if: :cn do
    validates :cn, uniqueness: { scope: [:group_id, :provider] }
    validates :cn, presence: true
    validates :filter, absence: true
  end

  with_options if: :filter do
    validates :filter, uniqueness: { scope: [:group_id, :provider] }
    validates :filter, ldap_filter: true, presence: true
    validates :cn, absence: true
  end

  validates :group_access, :group_id, presence: true
  validates :group_access, inclusion: { in: Gitlab::Access.all_values }
  validates :provider, presence: true

  scope :with_provider, ->(provider) { where(provider: provider) }

  before_validation :nullify_blank_attributes

  def access_field
    group_access
  end

  def config
    Gitlab::Auth::LDAP::Config.new(provider)
  rescue Gitlab::Auth::LDAP::Config::InvalidProvider
    nil
  end

  # default to the first LDAP server
  def provider
    read_attribute(:provider) || Gitlab::Auth::LDAP::Config.providers.first
  end

  def provider_label
    config.label
  end

  def active?
    if filter.present?
      ::License.feature_available?(:ldap_group_sync_filter)
    elsif cn.present?
      ::License.feature_available?(:ldap_group_sync)
    end
  end

  private

  def nullify_blank_attributes
    BLANK_ATTRIBUTES.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
