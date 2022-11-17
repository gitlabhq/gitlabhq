# frozen_string_literal: true

class RequireVerificationForNamespaceCreationExperiment < ApplicationExperiment
  control { false }
  candidate { true }

  exclude :existing_user

  EXPERIMENT_START_DATE = Date.new(2022, 1, 31)

  def candidate?
    run
  end

  private

  def existing_user
    return false unless user_or_actor

    user_or_actor.created_at < EXPERIMENT_START_DATE
  end
end
