# frozen_string_literal: true

# This model is not used yet, it will be used for:
# https://gitlab.com/gitlab-org/gitlab-ce/issues/48483
class ResourceLabelEvent < ActiveRecord::Base
<<<<<<< HEAD
  prepend EE::ResourceLabelEvent

=======
>>>>>>> upstream/master
  belongs_to :user
  belongs_to :issue
  belongs_to :merge_request
  belongs_to :label

  validates :user, presence: true, on: :create
  validates :label, presence: true, on: :create
  validate :exactly_one_issuable

  enum action: {
    add: 1,
    remove: 2
  }

  def self.issuable_columns
    %i(issue_id merge_request_id).freeze
  end

  def issuable
    issue || merge_request
  end

  private

  def exactly_one_issuable
    if self.class.issuable_columns.count { |attr| self[attr] } != 1
      errors.add(:base, "Exactly one of #{self.class.issuable_columns.join(', ')} is required")
    end
  end
end
