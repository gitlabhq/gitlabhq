class Identity < ActiveRecord::Base
  include Sortable
  include CaseSensitivity
  belongs_to :user

  validates :provider, presence: true
  validates :extern_uid, allow_blank: true, uniqueness: { scope: :provider }
  validates :user_id, uniqueness: { scope: :provider }

  scope :with_extern_uid, ->(provider, extern_uid) do
    extern_uid = Gitlab::LDAP::Person.normalize_dn(extern_uid) if provider.starts_with?('ldap')
    where(extern_uid: extern_uid, provider: provider)
  end

  def ldap?
    provider.starts_with?('ldap')
  end
end
