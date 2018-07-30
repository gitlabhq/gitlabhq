# frozen_string_literal: true

class ResourceLabelEvent < ActiveRecord::Base
  prepend EE::ResourceLabelEvent

  ISSUABLE_COLUMNS = %i(issue_id merge_request_id).freeze

  belongs_to :user
  belongs_to :issue
  belongs_to :merge_request
  belongs_to :label

  validates :user, presence: true, on: :create
  validates :label, presence: true, on: :create
  validate :issuable_id_is_present

  enum action: {
    add: 1,
    remove: 2
  }

  def issuable
    issue || merge_request
  end

  private

  def issuable_columns
    ISSUABLE_COLUMNS
  end

  def issuable_id_is_present
    ids = issuable_columns.find_all {|attr| self[attr]}

    if ids.size != 1
      errors.add(:base, "Exactly one of #{issuable_columns.join(', ')} is required")
    end
  end
end
