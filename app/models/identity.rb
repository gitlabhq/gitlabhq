class Identity < ActiveRecord::Base
  include Sortable
  include CaseSensitivity
  belongs_to :user

  validates :provider, presence: true
  validates :extern_uid, allow_blank: true, uniqueness: { scope: :provider }
  validates :user_id, uniqueness: { scope: :provider }

<<<<<<< HEAD
  scope :with_provider, ->(provider) { where(provider: provider) }
=======
  scope :with_extern_uid, ->(provider, extern_uid) { where(extern_uid: extern_uid, provider: provider) }
>>>>>>> ce/master

  def ldap?
    provider.starts_with?('ldap')
  end
end
