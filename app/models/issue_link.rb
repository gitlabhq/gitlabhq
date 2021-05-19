# frozen_string_literal: true

class IssueLink < ApplicationRecord
  include FromUnion

  belongs_to :source, class_name: 'Issue'
  belongs_to :target, class_name: 'Issue'

  validates :source, presence: true
  validates :target, presence: true
  validates :source, uniqueness: { scope: :target_id, message: 'is already related' }
  validate :check_self_relation
  validate :check_opposite_relation

  scope :for_source_issue, ->(issue) { where(source_id: issue.id) }
  scope :for_target_issue, ->(issue) { where(target_id: issue.id) }

  TYPE_RELATES_TO = 'relates_to'
  TYPE_BLOCKS = 'blocks'
  # we don't store is_blocked_by in the db but need it for displaying the relation
  # from the target (used in IssueLink.inverse_link_type)
  TYPE_IS_BLOCKED_BY = 'is_blocked_by'

  enum link_type: { TYPE_RELATES_TO => 0, TYPE_BLOCKS => 1 }

  def self.inverse_link_type(type)
    type
  end

  private

  def check_self_relation
    return unless source && target

    if source == target
      errors.add(:source, 'cannot be related to itself')
    end
  end

  def check_opposite_relation
    return unless source && target

    if IssueLink.find_by(source: target, target: source)
      errors.add(:source, 'is already related to this issue')
    end
  end
end

IssueLink.prepend_mod_with('IssueLink')
