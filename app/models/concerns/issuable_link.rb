# frozen_string_literal: true

# == IssuableLink concern
#
# Contains common functionality shared between related Issues and related Epics
#
# Used by IssueLink, Epic::RelatedEpicLink
#
module IssuableLink
  extend ActiveSupport::Concern

  TYPE_RELATES_TO = 'relates_to'
  TYPE_BLOCKS = 'blocks'
  # we don't store is_blocked_by in the db but need it for displaying the relation
  # from the target
  TYPE_IS_BLOCKED_BY = 'is_blocked_by'

  class_methods do
    def inverse_link_type(type)
      type
    end
  end

  included do
    validates :source, presence: true
    validates :target, presence: true
    validates :source, uniqueness: { scope: :target_id, message: 'is already related' }
    validate :check_self_relation
    validate :check_opposite_relation

    enum link_type: { TYPE_RELATES_TO => 0, TYPE_BLOCKS => 1 }

    private

    def check_self_relation
      return unless source && target

      if source == target
        errors.add(:source, 'cannot be related to itself')
      end
    end

    def check_opposite_relation
      return unless source && target

      if self.class.base_class.find_by(source: target, target: source)
        errors.add(:source, "is already related to this #{issuable_type}")
      end
    end

    def issuable_type
      raise NotImplementedError
    end
  end
end
