# frozen_string_literal: true

module WorkItems
  class WidgetDefinition < ApplicationRecord
    include IgnorableColumns

    self.table_name = 'work_item_widget_definitions'

    ignore_column :namespace_id, remove_with: '17.5', remove_after: '2024-09-19'

    belongs_to :work_item_type, class_name: 'WorkItems::Type', inverse_of: :widget_definitions

    validates :name, presence: true
    validates :name, uniqueness: { case_sensitive: false, scope: :work_item_type_id }
    validates :name, length: { maximum: 255 }

    validates :widget_options, if: :weight?,
      json_schema: { filename: 'work_item_weight_widget_options', hash_conversion: true }
    validates :widget_options, absence: true, unless: :weight?

    scope :enabled, -> { where(disabled: false) }

    enum widget_type: {
      assignees: 0,
      description: 1,
      hierarchy: 2,
      labels: 3,
      milestone: 4,
      notes: 5,
      start_and_due_date: 6,
      health_status: 7, # EE-only
      weight: 8, # EE-only
      iteration: 9, # EE-only
      progress: 10, # EE-only
      status: 11, # EE-only
      requirement_legacy: 12, # EE-only
      test_reports: 13, # EE-only
      notifications: 14,
      current_user_todos: 15,
      award_emoji: 16,
      linked_items: 17,
      color: 18, # EE-only
      rolledup_dates: 19, # EE-only
      participants: 20,
      time_tracking: 21,
      designs: 22,
      development: 23,
      crm_contacts: 24
    }

    attribute :widget_options, :ind_jsonb

    def self.available_widgets
      enabled.filter_map(&:widget_class).uniq
    end

    def self.widget_classes
      WorkItems::WidgetDefinition.widget_types.keys.filter_map do |type|
        WorkItems::Widgets.const_get(type.camelize, false)
      rescue NameError
        nil
      end
    end

    def widget_class
      return unless widget_type

      WorkItems::Widgets.const_get(widget_type.camelize, false)
    rescue NameError
      nil
    end
  end
end
