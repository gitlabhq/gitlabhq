# frozen_string_literal: true

class InProductGuidanceEnvironmentsWebideExperiment < ApplicationExperiment
  exclude :has_environments?

  def control_behavior
    false
  end

  private

  def has_environments?
    !context.project.environments.empty?
  end
end
