# frozen_string_literal: true

class UserSyncedAttributesMetadata < ApplicationRecord
  belongs_to :user

  validates :user, presence: true

  SYNCABLE_ATTRIBUTES = %i[name email location].freeze

  def read_only?(attribute)
    sync_profile_from_provider? && synced?(attribute)
  end

  def read_only_attributes
    return [] unless sync_profile_from_provider?

    SYNCABLE_ATTRIBUTES.select { |key| synced?(key) }
  end

  def synced?(attribute)
    read_attribute("#{attribute}_synced")
  end

  def set_attribute_synced(attribute, value)
    write_attribute("#{attribute}_synced", value)
  end

  class << self
    def syncable_attributes(provider = nil)
      return SYNCABLE_ATTRIBUTES unless provider && ldap_provider?(provider)
      return SYNCABLE_ATTRIBUTES if ldap_sync_name?(provider)

      SYNCABLE_ATTRIBUTES - %i[name]
    end
  end

  private

  def sync_profile_from_provider?
    Gitlab::Auth::OAuth::Provider.sync_profile_from_provider?(provider)
  end

  class << self
    def ldap_provider?(provider)
      Gitlab::Auth::OAuth::Provider.ldap_provider?(provider)
    end

    def ldap_sync_name?(provider)
      return false unless provider

      config = Gitlab::Auth::Ldap::Config.new(provider)
      config.enabled? && config.sync_name
    end
  end
end
