# frozen_string_literal: true

module WorkItems
  module SavedViews
    class SavedView < ApplicationRecord
      include Spammable

      belongs_to :namespace
      belongs_to :author, foreign_key: :created_by_id, optional: true, inverse_of: :created_saved_views,
        class_name: 'User'

      has_many :user_saved_views, class_name: 'WorkItems::SavedViews::UserSavedView', inverse_of: :saved_view
      has_many :subscribed_users, through: :user_saved_views, source: :user

      validates :name, presence: true, length: { maximum: 140 }
      validates :description, length: { maximum: 140 }, allow_blank: true
      validates :version, presence: true, numericality: { greater_than: 0 }
      validates :private, inclusion: { in: [true, false] }

      validates :filter_data, json_schema: { filename: "saved_view_filters", size_limit: 8.kilobytes }
      validates :display_settings,
        json_schema: { filename: 'work_item_user_preference_display_settings', size_limit: 8.kilobytes }

      attr_spammable :name, spam_title: true

      enum :sort, ::WorkItems::SortingKeys.all.keys

      def unsubscribe_other_users!(user:)
        user_saved_views.where.not(user: user).delete_all
      end
    end
  end
end
