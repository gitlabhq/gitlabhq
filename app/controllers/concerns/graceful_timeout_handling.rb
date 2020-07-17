# frozen_string_literal: true

module GracefulTimeoutHandling
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::QueryCanceled do |exception|
      raise exception unless request.format.json?

      log_exception(exception)

      render json: { error: _('There is too much data to calculate. Please change your selection.') }
    end
  end
end
