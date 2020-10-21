# frozen_string_literal: true

module RunnerSetupScripts
  extend ActiveSupport::Concern

  private

  def private_runner_setup_scripts(**kwargs)
    instructions = Gitlab::Ci::RunnerInstructions.new(current_user: current_user, os: script_params[:os], arch: script_params[:arch], **kwargs)
    output = {
      install: instructions.install_script,
      register: instructions.register_command
    }

    if instructions.errors.any?
      render json: { errors: instructions.errors }, status: :bad_request
    else
      render json: output
    end
  end

  def script_params
    params.permit(:os, :arch)
  end
end
