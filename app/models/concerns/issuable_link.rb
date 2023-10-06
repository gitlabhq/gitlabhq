# frozen_string_literal: true

# == IssuableLink concern
#
# Contains common functionality shared between related Issues and related Epics
#
# Used by IssueLink, Epic::RelatedEpicLink
#
module IssuableLink
  extend ActiveSupport::Concern

  MAX_LINKS_COUNT = 100
  TYPE_RELATES_TO = Enums::IssuableLink::TYPE_RELATES_TO

  class_methods do
    def inverse_link_type(type)
      type
    end

    def issuable_type
      raise NotImplementedError
    end

    def issuable_name
      issuable_type.to_s.humanize(capitalize: false)
    end

    # Used to get the available types for the API
    # overriden in EE
    def available_link_types
      [TYPE_RELATES_TO]
    end
  end

  included do
    validates :source, presence: true
    validates :target, presence: true
    validates :source, uniqueness: { scope: :target_id, message: 'is already related' }
    validate :check_self_relation
    validate :check_opposite_relation
    validate :validate_max_number_of_links, on: :create

    scope :for_source_or_target, ->(issuable) { where(source: issuable).or(where(target: issuable)) }

    enum link_type: Enums::IssuableLink.link_types

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
        errors.add(:source, "is already related to this #{self.class.issuable_name}")
      end
    end

    def validate_max_number_of_links
      return unless source && target

      validate_max_number_of_links_for(source, :source)
      validate_max_number_of_links_for(target, :target)
    end

    def validate_max_number_of_links_for(item, attribute_name)
      return unless item.linked_items_count >= MAX_LINKS_COUNT

      errors.add(
        attribute_name,
        format(
          s_('This %{issuable} would exceed the maximum number of linked %{issuables} (%{limit}).'),
          issuable: self.class.issuable_name,
          issuables: self.class.issuable_name.pluralize,
          limit: MAX_LINKS_COUNT
        )
      )
    end
  end
end

IssuableLink.prepend_mod_with('IssuableLink')
IssuableLink::ClassMethods.prepend_mod_with('IssuableLink::ClassMethods')
