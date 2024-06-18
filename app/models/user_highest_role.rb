# frozen_string_literal: true

class UserHighestRole < ApplicationRecord
  belongs_to :user, optional: false

  validates :highest_access_level, allow_nil: true, inclusion: { in: ->(_) { self.allowed_values } }

  scope :with_highest_access_level, ->(highest_access_level) { where(highest_access_level: highest_access_level) }

  def self.allowed_values
    Gitlab::Access.all_values
  end
end

UserHighestRole.prepend_mod
