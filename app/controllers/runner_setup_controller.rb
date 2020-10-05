# frozen_string_literal: true

class RunnerSetupController < ApplicationController
  def platforms
    render json: Gitlab::Ci::RunnerInstructions::OS.merge(Gitlab::Ci::RunnerInstructions::OTHER_ENVIRONMENTS)
  end
end
