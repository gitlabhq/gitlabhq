# frozen_string_literal: true

module Achievements
  class Achievement < ApplicationRecord
    include Avatarable
    include StripAttribute
    include IgnorableColumns

    ignore_column :revokable, remove_with: '15.11', remove_after: '2023-04-22'

    belongs_to :namespace, inverse_of: :achievements, optional: false

    has_many :user_achievements, inverse_of: :achievement
    has_many :users, through: :user_achievements, inverse_of: :achievements

    strip_attributes! :name, :description

    validates :name,
              presence: true,
              length: { maximum: 255 },
              uniqueness: { case_sensitive: false, scope: [:namespace_id] }
    validates :description, length: { maximum: 1024 }
  end
end
