# frozen_string_literal: true

module WorkItems
  module SavedViews
    class UserSavedView < ApplicationRecord
      belongs_to :namespace
      belongs_to :user, inverse_of: :user_saved_views
      belongs_to :saved_view, class_name: 'WorkItems::SavedViews::SavedView', inverse_of: :user_saved_views

      validates :saved_view_id, uniqueness: { scope: :user_id }
    end
  end
end
