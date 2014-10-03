class LdapGroupLink < ActiveRecord::Base
  include Gitlab::Access
  belongs_to :group

  validates :cn, :group_access, :group_id, presence: true
  validates :cn, uniqueness: { scope: :group_id }
  validates :group_access, inclusion: { in: Gitlab::Access.all_values }

  def access_field
    group_access
  end
end
