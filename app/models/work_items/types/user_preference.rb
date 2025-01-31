# frozen_string_literal: true

module WorkItems
  module Types
    class UserPreference < ApplicationRecord
      self.table_name = 'work_item_type_user_preferences'

      belongs_to :user
      belongs_to :namespace
      belongs_to :work_item_type,
        class_name: 'WorkItems::Type',
        primary_key: :correct_id,
        inverse_of: :user_preferences,
        optional: true
    end
  end
end
