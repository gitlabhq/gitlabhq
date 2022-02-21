# frozen_string_literal: true

class InProductGuidanceEnvironmentsWebideExperiment < ApplicationExperiment
  control { false }

  exclude :has_environments?

  private

  def has_environments?
    !context.project.environments.empty?
  end
end
