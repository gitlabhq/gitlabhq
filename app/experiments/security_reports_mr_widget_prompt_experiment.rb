# frozen_string_literal: true

class SecurityReportsMrWidgetPromptExperiment < ApplicationExperiment
  def publish(_result = nil)
    super

    publish_to_database
  end

  # This is a purely client side experiment, and since we don't have a nicer
  # way to define variants yet, we define them here.
  def candidate_behavior
  end
end
