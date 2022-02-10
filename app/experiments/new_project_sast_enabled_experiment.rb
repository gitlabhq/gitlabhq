# frozen_string_literal: true

class NewProjectSastEnabledExperiment < ApplicationExperiment
  def publish(_result = nil)
    super

    publish_to_database
  end

  def candidate_behavior
  end

  def free_indicator_behavior
  end

  def unchecked_candidate_behavior
  end

  def unchecked_free_indicator_behavior
  end
end
