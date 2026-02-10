# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module Custom
      class Type < ApplicationRecord
        self.table_name = 'work_item_custom_types'

        include ActiveRecord::FixedItemsModel::HasOne

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

        validate :system_defined_names_unique_across_parent_scope
        validate :max_types_per_parent_limit, on: :create

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

        private

        def strip_whitespaces
          self.name = name&.strip
        end

        def sharding_keys
          [:namespace_id, :organization_id]
        end

        def system_defined_names_unique_across_parent_scope
          return if name.blank?

          system_type = WorkItems::TypesFramework::SystemDefined::Type.find_by_name(name)

          return unless system_type

          # Allow the same name if this custom type is converted from that exact system defined type
          return if converted_from_system_defined_type_identifier == system_type.id

          # Allow if the system-defined name is available across namespace/organization
          # i.e a type was converted from the :issue type but renamed to something else, so "Issue" is still available
          return if system_defined_name_available?(system_type)

          errors.add(:name, format(_("'%{name}' is already taken"), name: name))
        end

        def system_defined_name_available?(system_type)
          converted_type = self.class
            .where(parent_scope_conditions)
            .excluding(self)
            .find_by(converted_from_system_defined_type_identifier: system_type.id)

          # Name is available if there's a converted type that uses a DIFFERENT name
          # than the system defined type it was converted from
          converted_type.present? && !(converted_type.name.casecmp(system_type.name) == 0)
        end

        def max_types_per_parent_limit
          return unless organization_id.present? || namespace_id.present?
          return unless self.class.where(parent_scope_conditions).count >= MAX_TYPE_PER_PARENT

          parent_attribute = organization_id.present? ? :organization : :namespace

          errors.add(parent_attribute,
            format(_('can only have a maximum of %{limit} work item types.'), limit: MAX_TYPE_PER_PARENT)
          )
        end

        def parent_scope_conditions
          if organization_id.present?
            { organization_id: organization_id }
          else
            { namespace_id: namespace_id }
          end
        end
      end
    end
  end
end
