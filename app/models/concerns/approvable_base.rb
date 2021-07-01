# frozen_string_literal: true

module ApprovableBase
  extend ActiveSupport::Concern
  include FromUnion

  included do
    has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
    has_many :approved_by_users, through: :approvals, source: :user

    scope :without_approvals, -> { left_outer_joins(:approvals).where(approvals: { id: nil }) }
    scope :with_approvals, -> { joins(:approvals) }
    scope :approved_by_users_with_ids, -> (*user_ids) do
      with_approvals
        .merge(Approval.with_user)
        .where(users: { id: user_ids })
        .group(:id)
        .having("COUNT(users.id) = ?", user_ids.size)
    end
    scope :approved_by_users_with_usernames, -> (*usernames) do
      with_approvals
        .merge(Approval.with_user)
        .where(users: { username: usernames })
        .group(:id)
        .having("COUNT(users.id) = ?", usernames.size)
    end

    scope :not_approved_by_users_with_usernames, -> (usernames) do
      users = User.where(username: usernames).select(:id)
      self_table = self.arel_table
      app_table = Approval.arel_table

      where(
        Approval.where(approvals: { user_id: users })
        .where(app_table[:merge_request_id].eq(self_table[:id]))
        .select('true')
        .arel.exists.not
      )
    end
  end

  class_methods do
    def select_from_union(relations)
      where(id: from_union(relations))
    end
  end

  def approved_by?(user)
    return false unless user

    approved_by_users.include?(user)
  end

  def can_be_approved_by?(user)
    user && !approved_by?(user) && user.can?(:approve_merge_request, self)
  end
end
