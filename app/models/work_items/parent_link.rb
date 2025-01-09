# frozen_string_literal: true

module WorkItems
  class ParentLink < ApplicationRecord
    include RelativePositioning
    include EachBatch

    self.table_name = 'work_item_parent_links'

    MAX_CHILDREN = 5000

    belongs_to :work_item
    belongs_to :work_item_parent, class_name: 'WorkItem'

    validates :work_item_parent, presence: true
    validates :work_item, presence: true, uniqueness: true
    validate :validate_hierarchy_restrictions
    validate :validate_cyclic_reference
    validate :validate_max_children
    validate :validate_confidentiality
    validate :check_existing_related_link, on: :create

    scope :for_parents, ->(parent_ids) { where(work_item_parent_id: parent_ids) }
    scope :for_children, ->(children_ids) { where(work_item: children_ids) }

    class << self
      def has_public_children?(parent_id)
        joins(:work_item).where(work_item_parent_id: parent_id, 'issues.confidential': false).exists?
      end

      def has_confidential_parent?(id)
        link = find_by_work_item_id(id)
        return false unless link

        link.work_item_parent.confidential?
      end

      def relative_positioning_query_base(parent_link)
        where(work_item_parent_id: parent_link.work_item_parent_id)
      end

      def relative_positioning_parent_column
        :work_item_parent_id
      end

      def for_work_item(work_item)
        find_or_initialize_by(work_item: work_item)
      end
    end

    private

    def validate_max_children
      return unless work_item_parent && work_item_parent_id_changed?

      max = persisted? ? MAX_CHILDREN : MAX_CHILDREN - 1
      if work_item_parent.child_links.count > max
        errors.add :work_item_parent, _('parent already has maximum number of children.')
      end
    end

    def validate_confidentiality
      return unless work_item_parent && work_item

      if work_item_parent.confidential? && !work_item.confidential?
        errors.add :work_item, format(
          _("cannot assign a non-confidential %{work_item_type} to a confidential "\
                    "parent. Make the %{work_item_type} confidential and try again."),
          work_item_type: work_item.work_item_type.name.downcase
        )
      end
    end

    def validate_hierarchy_restrictions
      return unless work_item && work_item_parent

      restriction = ::WorkItems::HierarchyRestriction
        .find_by_parent_type_id_and_child_type_id(work_item_parent.work_item_type_id, work_item.work_item_type_id)

      if restriction.nil?
        errors.add :work_item, _("it's not allowed to add this type of parent item")
        return
      end

      validate_depth(restriction.maximum_depth)
      validate_cross_hierarchy(restriction.cross_hierarchy_enabled)
    end

    def validate_cross_hierarchy(cross_hierarchy_enabled)
      return if cross_hierarchy_enabled
      return if work_item.resource_parent == work_item_parent.resource_parent

      errors.add :work_item_parent, _('parent must be in the same project or group as child.')
    end

    def validate_depth(depth)
      return unless depth
      return if work_item.work_item_type_id != work_item_parent.work_item_type_id

      if work_item_parent.same_type_base_and_ancestors.count + work_item.same_type_descendants_depth > depth
        errors.add :work_item, _('reached maximum depth')
      end
    end

    def validate_cyclic_reference
      return unless work_item_parent&.id && work_item&.id

      if work_item.id == work_item_parent.id
        errors.add :work_item, _('is not allowed to point to itself')
      end

      if work_item_parent.ancestors.detect { |ancestor| work_item.id == ancestor.id }
        errors.add :work_item, _("it's already present in this item's hierarchy")
      end
    end

    def check_existing_related_link
      return unless work_item && work_item_parent

      existing_link = WorkItems::RelatedWorkItemLink.for_items(work_item, work_item_parent)
      return if existing_link.none?

      errors.add(:work_item, _('cannot assign a linked work item as a parent'))
    end
  end
end

WorkItems::ParentLink.prepend_mod
