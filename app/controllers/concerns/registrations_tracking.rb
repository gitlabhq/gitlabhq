# frozen_string_literal: true

module RegistrationsTracking
  extend ActiveSupport::Concern

  included do
    helper_method :glm_tracking_params
  end

  private

  def glm_tracking_params
    params.permit(:glm_source, :glm_content)
  end
end

RegistrationsTracking.prepend_mod
