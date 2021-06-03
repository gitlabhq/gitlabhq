# frozen_string_literal: true

class Experiment < ApplicationRecord
  has_many :experiment_users
  has_many :experiment_subjects, inverse_of: :experiment

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }

  def self.add_user(name, group_type, user, context = {})
    find_or_create_by!(name: name).record_user_and_group(user, group_type, context)
  end

  def self.add_group(name, variant:, group:)
    add_subject(name, variant: variant, subject: group)
  end

  def self.add_subject(name, variant:, subject:)
    find_or_create_by!(name: name).record_subject_and_variant!(subject, variant)
  end

  def self.record_conversion_event(name, user, context = {})
    find_or_create_by!(name: name).record_conversion_event_for_user(user, context)
  end

  # Create or update the recorded experiment_user row for the user in this experiment.
  def record_user_and_group(user, group_type, context = {})
    experiment_user = experiment_users.find_or_initialize_by(user: user)
    experiment_user.assign_attributes(group_type: group_type, context: merged_context(experiment_user, context))
    # We only call save when necessary because this causes the request to stick to the primary DB
    # even when the save is a no-op
    # https://gitlab.com/gitlab-org/gitlab/-/issues/324649
    experiment_user.save! if experiment_user.changed?

    experiment_user
  end

  def record_conversion_event_for_user(user, context = {})
    experiment_user = experiment_users.find_by(user: user)
    return unless experiment_user

    experiment_user.update!(converted_at: Time.current, context: merged_context(experiment_user, context))
  end

  def record_subject_and_variant!(subject, variant)
    raise 'Incompatible subject provided!' unless ExperimentSubject.valid_subject?(subject)

    attr_name = subject.class.table_name.singularize.to_sym
    experiment_subject = experiment_subjects.find_or_initialize_by(attr_name => subject)
    experiment_subject.assign_attributes(variant: variant)
    # We only call save when necessary because this causes the request to stick to the primary DB
    # even when the save is a no-op
    # https://gitlab.com/gitlab-org/gitlab/-/issues/324649
    experiment_subject.save! if experiment_subject.changed?

    experiment_subject
  end

  private

  def merged_context(experiment_user, new_context)
    experiment_user.context.deep_merge(new_context.deep_stringify_keys)
  end
end
