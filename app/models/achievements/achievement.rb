# frozen_string_literal: true

module Achievements
  class Achievement < ApplicationRecord
    include Avatarable
    include StripAttribute

    belongs_to :namespace, inverse_of: :achievements, optional: false

    has_many :user_achievements, inverse_of: :achievement
    has_many :users, through: :user_achievements, inverse_of: :achievements

    strip_attributes! :name, :description

    validates :name,
      presence: true,
      length: { maximum: 255 },
      uniqueness: { case_sensitive: false, scope: [:namespace_id] }
    validates :description, length: { maximum: 1024 }

    def uploads_sharding_key
      { namespace_id: namespace_id }
    end
  end
end
