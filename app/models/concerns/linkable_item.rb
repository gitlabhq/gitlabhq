# frozen_string_literal: true

# == LinkableItem concern
#
# Contains common functionality shared between related issue links and related work item links
#
# Used by IssueLink, WorkItems::RelatedWorkItemLink
#
module LinkableItem
  extend ActiveSupport::Concern
  include FromUnion
  include IssuableLink

  included do
    validate :check_existing_parent_link, on: :create

    scope :for_source, ->(item) { where(source_id: item.id) }
    scope :for_target, ->(item) { where(target_id: item.id) }
    scope :for_source_and_target, ->(source, target) { where(source: source, target: target) }
    scope :for_items, ->(source, target) do
      where(source: source, target: target).or(where(source: target, target: source))
    end

    private

    def check_existing_parent_link
      return unless source && target

      existing_relation = WorkItems::ParentLink.for_parents([source, target]).for_children([source, target])
      return if existing_relation.none?

      errors.add(:source, format(_('is a parent or child of this %{item}'), item: self.class.issuable_name))
    end
  end
end

LinkableItem.include_mod_with('LinkableItem::Callbacks')
LinkableItem.prepend_mod_with('LinkableItem')
