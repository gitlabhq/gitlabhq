class ApproverGroup < ActiveRecord::Base
  belongs_to :target, polymorphic: true  # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :group

  validates :group, presence: true

  delegate :users, to: :group

  def self.filtered_approver_groups(approver_groups, user)
    public_or_visible_groups = Group.public_or_visible_to_user(user) # rubocop:disable Cop/GroupPublicOrVisibleToUser

    approver_groups.joins(:group).merge(public_or_visible_groups)
  end
end
