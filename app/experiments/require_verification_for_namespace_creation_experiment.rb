# frozen_string_literal: true

class RequireVerificationForNamespaceCreationExperiment < ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
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
end
