class Identity < ActiveRecord::Base
  include Sortable
  include CaseSensitivity

  belongs_to :user

  validates :provider, presence: true
  validates :extern_uid, allow_blank: true, uniqueness: { scope: :provider, case_sensitive: false }
  validates :user_id, uniqueness: { scope: :provider }

  scope :with_provider, ->(provider) { where(provider: provider) }
  scope :with_extern_uid, ->(provider, extern_uid) do
    iwhere(extern_uid: normalize_uid(provider, extern_uid)).with_provider(provider)
  end

  def ldap?
    provider.starts_with?('ldap')
  end

  def self.normalize_uid(provider, uid)
    if provider.to_s.starts_with?('ldap')
      Gitlab::LDAP::Person.normalize_dn(uid)
    else
      uid.to_s
    end
  end
end
