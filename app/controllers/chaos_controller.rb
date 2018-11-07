# frozen_string_literal: true

class ChaosController < ActionController::Base
  before_action :validate_request

  def leakmem
    memory_mb = (params[:memory_mb]&.to_i || 100)
    duration_s = (params[:duration_s]&.to_i || 30).seconds

    start = Time.now
    retainer = []
    # Add `n` 1mb chunks of memory to the retainer array
    memory_mb.times { retainer << "x" * 1.megabyte }

    duration_taken = (Time.now - start).seconds
    Kernel.sleep duration_s - duration_taken if duration_s > duration_taken

    render text: "OK", content_type: 'text/plain'
  end

  def cpuspin
    duration_s = (params[:duration_s]&.to_i || 30).seconds
    end_time = Time.now + duration_s.seconds

    rand while Time.now < end_time

    render text: "OK", content_type: 'text/plain'
  end

  def sleep
    duration_s = (params[:duration_s]&.to_i || 30).seconds
    Kernel.sleep duration_s

    render text: "OK", content_type: 'text/plain'
  end

  def kill
    Process.kill("KILL", Process.pid)
  end

  private

  def validate_request
    secret = ENV['GITLAB_CHAOS_SECRET']
    # GITLAB_CHAOS_SECRET is required unless you're running in Development mode
    if !secret && !Rails.env.development?
      render text: "chaos misconfigured: please configure GITLAB_CHAOS_SECRET when using GITLAB_ENABLE_CHAOS_ENDPOINTS outside of a development environment", content_type: 'text/plain', status: 500
    end

    return unless secret

    unless request.headers["HTTP_X_CHAOS_SECRET"] == secret
      render text: "To experience chaos, please set X-Chaos-Secret header", content_type: 'text/plain', status: 401
    end
  end
end
