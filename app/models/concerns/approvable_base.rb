# frozen_string_literal: true

module ApprovableBase
  extend ActiveSupport::Concern

  included do
    has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
    has_many :approved_by_users, through: :approvals, source: :user
  end

  def approved_by?(user)
    return false unless user

    approved_by_users.include?(user)
  end
end
