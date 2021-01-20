# frozen_string_literal: true

class Experiment < ApplicationRecord
  has_many :experiment_users
  has_many :experiment_subjects, inverse_of: :experiment

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }

  def self.add_user(name, group_type, user, context = {})
    find_or_create_by!(name: name).record_user_and_group(user, group_type, context)
  end

  def self.record_conversion_event(name, user)
    find_or_create_by!(name: name).record_conversion_event_for_user(user)
  end

  # Create or update the recorded experiment_user row for the user in this experiment.
  def record_user_and_group(user, group_type, context = {})
    experiment_user = experiment_users.find_or_initialize_by(user: user)
    merged_context = experiment_user.context.deep_merge(context.deep_stringify_keys)
    experiment_user.update!(group_type: group_type, context: merged_context)
  end

  def record_conversion_event_for_user(user)
    experiment_users.find_by(user: user, converted_at: nil)&.touch(:converted_at)
  end
end
