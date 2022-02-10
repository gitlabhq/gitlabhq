# frozen_string_literal: true

class RequireVerificationForNamespaceCreationExperiment < ApplicationExperiment
  exclude :existing_user

  EXPERIMENT_START_DATE = Date.new(2022, 1, 31)

  def control_behavior
    false
  end

  def candidate_behavior
    true
  end

  def candidate?
    run
  end

  def record_conversion(namespace)
    return unless should_track?

    Experiment.by_name(name).record_conversion_event_for_subject(subject, namespace_id: namespace.id)
  end

  private

  def subject
    context.value[:user]
  end

  def existing_user
    return false unless user_or_actor

    user_or_actor.created_at < EXPERIMENT_START_DATE
  end
end
