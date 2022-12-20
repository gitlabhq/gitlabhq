# frozen_string_literal: true

module Achievements
  class Achievement < ApplicationRecord
    include Avatarable
    include StripAttribute

    belongs_to :namespace, inverse_of: :achievements, optional: false

    strip_attributes! :name, :description

    validates :name,
              presence: true,
              length: { maximum: 255 },
              uniqueness: { case_sensitive: false, scope: [:namespace_id] }
    validates :description, length: { maximum: 1024 }
  end
end
