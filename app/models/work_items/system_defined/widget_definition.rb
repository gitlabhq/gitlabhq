# frozen_string_literal: true

module WorkItems
  module SystemDefined
    class WidgetDefinition
      include ActiveRecord::FixedItemsModel::Model
      include ActiveRecord::FixedItemsModel::HasOne

      auto_generate_ids!

      attribute :widget_type, :string
      attribute :widget_options, ::Gitlab::Database::Type::IndifferentJsonb.new
      attribute :work_item_type_id, :integer
      attribute :name, :string

      belongs_to_fixed_items :work_item_type, fixed_items_class: WorkItems::SystemDefined::Type

      validates :widget_type, presence: true
      validates :work_item_type_id, presence: true

      class << self
        def fixed_items
          # Instead of having a huge matrix here, let's build the items based on a configuration module per type.
          Type.all.flat_map do |type|
            configuration_class = type.configuration_class
            configuration_class.widgets.map do |widget_type|
              {
                widget_type: widget_type.to_s,
                work_item_type_id: type.id,
                widget_options: configuration_class.widget_options[widget_type.to_sym],
                name: widget_type.to_s.humanize
              }.compact
            end
          end
        end

        # List of all available widgets as strings
        def widget_types
          %w[
            assignees
            award_emoji
            crm_contacts
            current_user_todos
            description
            designs
            development
            email_participants
            error_tracking
            hierarchy
            labels
            linked_items
            linked_resources
            milestone
            notes
            notifications
            participants
            start_and_due_date
            time_tracking
          ]
        end

        # List of all available widgets as classes
        def available_widgets
          widget_types.map do |type|
            new(widget_type: type).widget_class
          end
        end
      end

      def widget_class
        return unless widget_type

        WorkItems::Widgets.const_get(widget_type.camelize, false)
      rescue NameError
        nil
      end

      def build_widget(work_item)
        widget_class.new(work_item, widget_definition: self)
      end

      # all CE widgets are available without license, we override this method in EE
      def licensed?(_resource_parent)
        true
      end
    end
  end
end

WorkItems::SystemDefined::WidgetDefinition.prepend_mod
