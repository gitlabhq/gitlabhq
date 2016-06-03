# == Schema Information
#
# Table name: identities
#
#  id         :integer          not null, primary key
#  extern_uid :string
#  provider   :string
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class Identity < ActiveRecord::Base
  include Sortable
  include CaseSensitivity
  belongs_to :user

  validates :provider, presence: true
  validates :extern_uid, allow_blank: true, uniqueness: { scope: :provider }
  validates :user_id, uniqueness: { scope: :provider }

  def ldap?
    provider.starts_with?('ldap')
  end
end
