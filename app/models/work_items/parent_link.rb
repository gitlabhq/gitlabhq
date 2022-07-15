# frozen_string_literal: true

module WorkItems
  class ParentLink < ApplicationRecord
    self.table_name = 'work_item_parent_links'

    MAX_CHILDREN = 100
    PARENT_TYPES = [:issue, :incident].freeze

    belongs_to :work_item
    belongs_to :work_item_parent, class_name: 'WorkItem'

    validates :work_item_parent, presence: true
    validates :work_item, presence: true, uniqueness: true
    validate :validate_child_type
    validate :validate_parent_type
    validate :validate_same_project
    validate :validate_max_children

    private

    def validate_child_type
      return unless work_item

      unless work_item.task?
        errors.add :work_item, _('only Task can be assigned as a child in hierarchy.')
      end
    end

    def validate_parent_type
      return unless work_item_parent

      base_type = work_item_parent.work_item_type.base_type.to_sym
      unless PARENT_TYPES.include?(base_type)
        parent_names = WorkItems::Type::BASE_TYPES.slice(*WorkItems::ParentLink::PARENT_TYPES)
          .values.map { |type| type[:name] }

        errors.add :work_item_parent, _('only %{parent_types} can be parent of Task.') %
                                        { parent_types: parent_names.to_sentence }
      end
    end

    def validate_same_project
      return if work_item.nil? || work_item_parent.nil?

      if work_item.resource_parent != work_item_parent.resource_parent
        errors.add :work_item_parent, _('parent must be in the same project as child.')
      end
    end

    def validate_max_children
      return unless work_item_parent

      max = persisted? ? MAX_CHILDREN : MAX_CHILDREN - 1
      if work_item_parent.child_links.count > max
        errors.add :work_item_parent, _('parent already has maximum number of children.')
      end
    end
  end
end
