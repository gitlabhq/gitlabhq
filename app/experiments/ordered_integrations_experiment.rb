# frozen_string_literal: true

class OrderedIntegrationsExperiment < ApplicationExperiment
  def self.context_keys = %i[actor]

  control
  variant(:candidate)

  private

  def control_behavior; end
  def candidate_behavior; end
end
