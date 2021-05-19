# frozen_string_literal: true

class Identity < ApplicationRecord
  include Sortable
  include CaseSensitivity

  belongs_to :user

  validates :provider, presence: true
  validates :extern_uid, allow_blank: true, uniqueness: { scope: UniquenessScopes.scopes, case_sensitive: false }
  validates :user, uniqueness: { scope: UniquenessScopes.scopes }

  before_save :ensure_normalized_extern_uid, if: :extern_uid_changed?
  after_destroy :clear_user_synced_attributes, if: :user_synced_attributes_metadata_from_provider?

  scope :for_user, ->(user) { where(user: user) }
  scope :with_provider, ->(provider) { where(provider: provider) }
  scope :with_extern_uid, ->(provider, extern_uid) do
    iwhere(extern_uid: normalize_uid(provider, extern_uid)).with_provider(provider)
  end
  scope :with_any_extern_uid, ->(provider) do
    where.not(extern_uid: nil).with_provider(provider)
  end

  def ldap?
    Gitlab::Auth::OAuth::Provider.ldap_provider?(provider)
  end

  def self.normalize_uid(provider, uid)
    if Gitlab::Auth::OAuth::Provider.ldap_provider?(provider)
      Gitlab::Auth::Ldap::Person.normalize_dn(uid)
    else
      uid.to_s
    end
  end

  private

  def ensure_normalized_extern_uid
    return if extern_uid.nil?

    self.extern_uid = Identity.normalize_uid(self.provider, self.extern_uid)
  end

  def user_synced_attributes_metadata_from_provider?
    user.user_synced_attributes_metadata&.provider == provider
  end

  def clear_user_synced_attributes
    user.user_synced_attributes_metadata&.destroy
  end
end

Identity.prepend_mod_with('Identity')
