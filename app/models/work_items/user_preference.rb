# frozen_string_literal: true

module WorkItems
  class UserPreference < ApplicationRecord
    self.table_name = 'work_item_type_user_preferences'

    belongs_to :user
    belongs_to :namespace
    belongs_to :work_item_type,
      class_name: 'WorkItems::Type',
      inverse_of: :user_preferences,
      optional: true

    validate :validate_sort_value
    validates :display_settings, json_schema: { filename: 'work_item_user_preference_display_settings' }

    def self.create_or_update(namespace:, work_item_type_id:, user:, **attributes)
      record = find_or_initialize_by(namespace: namespace, work_item_type_id: work_item_type_id, user: user)
      record.assign_attributes(**attributes)
      record.save
      record
    end

    def self.find_by_user_namespace_and_work_item_type_id(user, namespace, work_item_type_id)
      find_by(
        user: user,
        namespace: namespace,
        work_item_type_id: work_item_type_id
      )
    end

    private

    def validate_sort_value
      return if sort.blank?
      return if ::WorkItems::SortingKeys.available?(sort, widget_list: work_item_type&.widget_classes(namespace))

      message =
        if work_item_type.present?
          format(
            _('value "%{sort}" is not available on %{namespace} for work items type %{wit}'),
            sort: sort,
            namespace: namespace.full_path,
            wit: work_item_type.name
          )
        else
          format(
            _('value "%{sort}" is not available on %{namespace}'),
            sort: sort,
            namespace: namespace.full_path
          )
        end

      errors.add(:sort, message)
    end
  end
end
