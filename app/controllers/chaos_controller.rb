# frozen_string_literal: true

class ChaosController < ActionController::Base
  def sleep
    duration_s = params[:duration_s] ? params[:duration_s].to_i : 30
    Kernel.sleep duration_s
    render text: "OK", content_type: 'text/plain'
  end
end
