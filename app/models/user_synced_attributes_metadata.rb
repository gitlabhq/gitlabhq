class UserSyncedAttributesMetadata < ActiveRecord::Base
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

  private

  def sync_profile_from_provider?
    Gitlab::Auth::OAuth::Provider.sync_profile_from_provider?(provider)
  end
end
