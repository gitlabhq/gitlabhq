class Identity < ActiveRecord::Base
  include Sortable
  include CaseSensitivity
  belongs_to :user

  validates :provider, presence: true
  validates :extern_uid, allow_blank: true, uniqueness: { scope: :provider }
  validates :user_id, uniqueness: { scope: :provider }

  scope :with_provider, ->(provider) { where(provider: provider) }

  def ldap?
    provider.starts_with?('ldap')
  end
end
