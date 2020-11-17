# frozen_string_literal: true

class Experiment < ApplicationRecord
  has_many :experiment_users

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }

  def self.add_user(name, group_type, user)
    return unless experiment = find_or_create_by(name: name)

    experiment.record_user_and_group(user, group_type)
  end

  # Create or update the recorded experiment_user row for the user in this experiment.
  def record_user_and_group(user, group_type)
    experiment_users.find_or_initialize_by(user: user).update!(group_type: group_type)
  end
end
