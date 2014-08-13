class LdapGroup < ActiveRecord::Base
  belongs_to :group

  validates :cn, uniqueness: { scope: :group_id }
end
