class Identity < ActiveRecord::Base
  include Sortable
  include CaseSensitivity
  belongs_to :user

  validates :provider, presence: true
  validates :extern_uid, allow_blank: true, uniqueness: { scope: :provider }
  validates :user_id, uniqueness: { scope: :provider }

<<<<<<< HEAD
  scope :with_provider, ->(provider) { where(provider: provider) }
  scope :with_extern_uid, ->(provider, extern_uid) { where(extern_uid: extern_uid, provider: provider) }
=======
  scope :with_extern_uid, ->(provider, extern_uid) do
    extern_uid = Gitlab::LDAP::Person.normalize_dn(extern_uid) if provider.starts_with?('ldap')
    where(extern_uid: extern_uid, provider: provider)
  end
>>>>>>> 6306e797acca358c79c120e5b12c29a5ec604571

  def ldap?
    provider.starts_with?('ldap')
  end
end
