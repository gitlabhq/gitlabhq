class Identity < ActiveRecord::Base
  prepend EE::Identity

  include Sortable
  include CaseSensitivity

  belongs_to :user

  validates :provider, presence: true
  validates :extern_uid, allow_blank: true, uniqueness: { scope: :provider, case_sensitive: false }
  validates :user_id, uniqueness: { scope: :provider }

  before_save :ensure_normalized_extern_uid, if: :extern_uid_changed?

  scope :with_provider, ->(provider) { where(provider: provider) }
  scope :with_extern_uid, ->(provider, extern_uid) do
    iwhere(extern_uid: normalize_uid(provider, extern_uid)).with_provider(provider)
  end

  def ldap?
    Gitlab::OAuth::Provider.ldap_provider?(provider)
  end

  def self.normalize_uid(provider, uid)
    if Gitlab::OAuth::Provider.ldap_provider?(provider)
      Gitlab::LDAP::Person.normalize_dn(uid)
    else
      uid.to_s
    end
  end

  private

  def ensure_normalized_extern_uid
    return if extern_uid.nil?

    self.extern_uid = Identity.normalize_uid(self.provider, self.extern_uid)
  end
end
