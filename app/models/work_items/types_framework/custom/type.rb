# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module Custom
      class Type < ApplicationRecord
        self.table_name = 'work_item_custom_types'

        include ActiveRecord::FixedItemsModel::HasOne

        # TODO: Add validation check for this limit
        MAX_TYPE_PER_PARENT = 30

        belongs_to :organization, class_name: 'Organizations::Organization', optional: true
        belongs_to :namespace, optional: true
        belongs_to_fixed_items :converted_from_system_defined_type,
          fixed_items_class: WorkItems::TypesFramework::SystemDefined::Type,
          foreign_key: 'converted_from_system_defined_type_identifier'

        enum :icon_name, {
          work_item_enhancement: 0,
          work_item_epic: 1,
          work_item_feature_flag: 2,
          work_item_feature: 3,
          work_item_incident: 4,
          work_item_issue: 5,
          work_item_keyresult: 6,
          work_item_maintenance: 7,
          work_item_objective: 8,
          work_item_requirement: 9,
          work_item_task: 10,
          work_item_test_case: 11,
          work_item_ticket: 12,
          bug: 13
        }

        before_validation :strip_whitespaces

        validates :name, presence: true
        validates :name, length: { maximum: 48 }
        validates :icon_name, presence: true
        validates :name, uniqueness: { case_sensitive: false, scope: [:organization_id, :namespace_id] }

        validates_with ExactlyOnePresentValidator, fields: :sharding_keys

        scope :for_organization, ->(organization) { where(organization_id: organization.id) }
        scope :for_namespace, ->(namespace) { where(namespace_id: namespace.id) }
        scope :order_by_name_asc, -> { order(arel_table[:name].lower.asc) }

        # Until we have widget customization etc. we can simply delegate to the system defined type
        delegate :supported_conversion_types, :widgets, :base_type, :widget_classes, :allowed_child_types,
          :allowed_parent_types, :descendant_types, to: :delegation_source

        def to_global_id(_options = {})
          converted_from_system_defined_type&.to_global_id ||
            ::Gitlab::GlobalId.build(self, model_name: 'WorkItems::TypesFramework::Custom::Type', id: id)
        end
        alias_method :to_gid, :to_global_id

        def parent
          organization || namespace
        end

        def delegation_source
          # use the associated system defined type as delegation source if set otherwise default to issue base type
          converted_from_system_defined_type || WorkItems::TypesFramework::SystemDefined::Type.default_issue_type
        end

        def icon_name_with_prefix
          icon_name.tr('_', '-').to_s
        end

        private

        def strip_whitespaces
          self.name = name&.strip
        end

        def sharding_keys
          [:namespace_id, :organization_id]
        end
      end
    end
  end
end
