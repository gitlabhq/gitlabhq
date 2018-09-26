# frozen_string_literal: true

module InvalidUTF8ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ArgumentError, with: :handle_invalid_utf8
  end

  private

  def handle_invalid_utf8(error)
    if error.message == "invalid byte sequence in UTF-8"
      render_412
    else
      raise(error)
    end
  end

  def render_412
    respond_to do |format|
      format.html { render "errors/precondition_failed", layout: "errors", status: 412 }
      format.js { render json: { error: 'Invalid UTF-8' }, status: :precondition_failed, content_type: 'application/json' }
      format.any { head :precondition_failed }
    end
  end
end
