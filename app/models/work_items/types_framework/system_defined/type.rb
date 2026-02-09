# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module SystemDefined
      class Type
        include ActiveRecord::FixedItemsModel::Model
        include GlobalID::Identification
        include Gitlab::Utils::StrongMemoize

        BASE_TYPES = [
          WorkItems::TypesFramework::SystemDefined::Definitions::Issue.configuration,
          WorkItems::TypesFramework::SystemDefined::Definitions::Incident.configuration,
          WorkItems::TypesFramework::SystemDefined::Definitions::Task.configuration,
          WorkItems::TypesFramework::SystemDefined::Definitions::Ticket.configuration
        ].freeze

        attribute :name, :string
        attribute :base_type, :string
        attribute :icon_name, :string

        class << self
          def fixed_items
            BASE_TYPES
          end

          # Helper method for the transition from the old `WorkItems::Type`
          # to the new `WorkItems::TypesFramework::SystemDefined::Type`
          #
          # TODO: Remove this once the transition is complete.
          # See https://gitlab.com/gitlab-org/gitlab/-/work_items/581926
          def base_types
            all.index_by(&:base_type)
          end

          def by_type(type)
            types = Array(type).map(&:to_s)
            where(base_type: types)
          end

          def find_by_type(type)
            find_by(base_type: type&.to_s)
          end

          def find_by_id(id)
            find_by(id: id&.to_i)
          end

          alias_method :default_by_type, :find_by_type

          def find_by_name(name)
            find_by(name: name.to_s)
          end

          def default_issue_type
            find_by_type(:issue)
          end

          def order_by_name_asc
            name_sorting_asc(all)
          end

          def by_ids_ordered_by_name(ids)
            name_sorting_asc(where(id: ids))
          end

          def by_base_type_ordered_by_name(types)
            name_sorting_asc(by_type(types))
          end

          def with_widget_definition(widget_type)
            all.select do |type|
              ::WorkItems::TypesFramework::SystemDefined::WidgetDefinition
                .where(work_item_type_id: type.id, widget_type: widget_type.to_s)
                .present?
            end
          end

          private

          def name_sorting_asc(items)
            items.sort_by { |type| type.name.downcase }
          end
        end

        BASE_TYPES.each do |type|
          define_method :"#{type[:base_type]}?" do
            base_type == type[:base_type]
          end
        end

        # Use legacy format
        def to_global_id(_options = {})
          ::Gitlab::GlobalId.build(self, model_name: 'WorkItems::Type', id: id)
        end
        alias_method :to_gid, :to_global_id

        def widget_definitions
          WorkItems::TypesFramework::SystemDefined::WidgetDefinition.where(work_item_type_id: id)
        end
        strong_memoize_attr :widget_definitions

        def widgets(_resource_parent)
          widget_definitions.filter(&:widget_class)
        end

        def widget_classes(resource_parent)
          widgets(resource_parent).map(&:widget_class)
        end

        def unavailable_widgets_on_conversion(target_type, resource_parent)
          source_widgets = widgets(resource_parent)
          target_widgets = target_type.widgets(resource_parent)
          target_widget_types = target_widgets.map(&:widget_type).to_set
          source_widgets.reject { |widget| target_widget_types.include?(widget.widget_type) }
        end

        # TODO: remove the supports_assignee? and supports_time_tracking? and replace it with this method
        def supports_widget?(resource_parent, widget_class)
          widget_classes(resource_parent).include?(widget_class)
        end

        # TODO: Move to something generic like .supports_widget?(widget_type)
        def supports_assignee?(resource_parent)
          widget_classes(resource_parent).include?(::WorkItems::Widgets::Assignees)
        end

        def supports_time_tracking?(resource_parent)
          widget_classes(resource_parent).include?(::WorkItems::Widgets::TimeTracking)
        end

        def allowed_child_types_by_name
          child_type_ids = WorkItems::TypesFramework::SystemDefined::HierarchyRestriction
            .where(parent_type_id: id)
            .map(&:child_type_id)

          self.class.by_ids_ordered_by_name(child_type_ids)
        end

        def allowed_parent_types_by_name
          parent_type_ids = WorkItems::TypesFramework::SystemDefined::HierarchyRestriction
            .where(child_type_id: id)
            .map(&:parent_type_id)

          self.class.by_ids_ordered_by_name(parent_type_ids)
        end

        def supported_conversion_types(resource_parent, user)
          type_names = supported_conversion_base_types(resource_parent, user) - [base_type]

          self.class.by_base_type_ordered_by_name(type_names)
        end

        def allowed_child_types(authorize: false, resource_parent: nil)
          types = allowed_child_types_by_name

          return types unless authorize

          authorized_types(types, resource_parent, licenses_for_child)
        end

        def allowed_parent_types(authorize: false, resource_parent: nil)
          types = allowed_parent_types_by_name

          return types unless authorize

          authorized_types(types, resource_parent, licenses_for_parent)
        end

        def descendant_types
          descendant_types = []
          next_level_child_types = allowed_child_types.to_a

          loop do
            descendant_types += next_level_child_types

            # We remove types that we've already seen to avoid circular dependencies
            next_level_child_types = next_level_child_types.flat_map do |type|
              type.allowed_child_types.to_a
            end - descendant_types

            break if next_level_child_types.empty?
          end

          descendant_types.uniq
        end
        strong_memoize_attr :descendant_types

        def configuration_class
          WorkItems::TypesFramework::SystemDefined::Definitions.const_get(base_type.camelize, false)
        end

        def license_name
          configuration_class.try(:license_name)
        end

        def licensed?
          license_name.present?
        end

        def supports_roadmap_view?
          configuration_class.try(:supports_roadmap_view?) || false
        end

        def use_legacy_view?
          configuration_class.try(:use_legacy_view?) || false
        end

        def can_promote_to_objective?
          configuration_class.try(:can_promote_to_objective?) || false
        end

        def show_project_selector?
          value = configuration_class.try(:show_project_selector?)
          value.nil? ? true : value
        end

        def supports_move_action?
          configuration_class.try(:supports_move_action?) || false
        end

        def service_desk?
          configuration_class.try(:service_desk?) || false
        end

        def incident_management?
          configuration_class.try(:incident_management?) || false
        end

        def configurable?
          value = configuration_class.try(:configurable?)
          value.nil? ? true : value
        end

        def creatable?
          value = configuration_class.try(:creatable?)
          value.nil? ? true : value
        end

        def visible_in_settings?
          value = configuration_class.try(:visible_in_settings?)
          value.nil? ? true : value
        end

        def archived?
          configuration_class.try(:archived?) || false
        end

        def filterable?
          configuration_class.try(:filterable?) || false
        end

        def only_for_group?
          configuration_class.try(:only_for_group?) || false
        end

        def enabled?
          true
        end

        private

        def licenses_for_parent
          configuration_class.try(:licenses_for_parent)
        end

        def licenses_for_child
          configuration_class.try(:licenses_for_child)
        end

        # resource_parent is used in EE
        def supported_conversion_base_types(_resource_parent, _user)
          self.class.all.map(&:base_type)
        end

        # overridden in EE to check for EE-specific restrictions
        def authorized_types(types, _resource_parent, _relation)
          types
        end
      end
    end
  end
end

WorkItems::TypesFramework::SystemDefined::Type.prepend_mod
