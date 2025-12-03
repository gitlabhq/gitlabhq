# frozen_string_literal: true

module WorkItems
  module SavedViews
    class SavedView < ApplicationRecord
      belongs_to :namespace
      belongs_to :author, foreign_key: :created_by_id, optional: true, inverse_of: :created_saved_views,
        class_name: 'User'

      has_many :user_saved_views, class_name: 'WorkItems::SavedViews::UserSavedView', inverse_of: :saved_view
      has_many :subscribed_users, through: :user_saved_views, source: :user

      validates :name, presence: true, length: { maximum: 140 }
      validates :description, length: { maximum: 140 }, allow_blank: true
      validates :version, presence: true, numericality: { greater_than: 0 }
      validates :private, inclusion: { in: [true, false] }
    end
  end
end
