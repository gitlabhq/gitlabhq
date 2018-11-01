# frozen_string_literal: true

class ChaosController < ActionController::Base
  before_action :validate_request

  def leakmem
    memory_mb = params[:memory_mb] ? params[:memory_mb].to_i : 100
    retainer = []

    memory_mb.times { retainer << "x" * (1024 * 1024) }
    render text: "OK", content_type: 'text/plain'
  end

  def cpuspin
    duration_s = params[:duration_s] ? params[:duration_s].to_i : 30
    end_time = Time.now + duration_s.seconds
    10_000.times { } while Time.now < end_time

    render text: "OK", content_type: 'text/plain'
  end

  def sleep
    duration_s = params[:duration_s] ? params[:duration_s].to_i : 30
    Kernel.sleep duration_s
    render text: "OK", content_type: 'text/plain'
  end

  def kill
    Process.kill("KILL", Process.pid)
  end

  private

  def validate_request
    secret = ENV['GITLAB_CHAOS_SECRET']
    return unless secret

    unless request.headers["HTTP_X_CHAOS_SECRET"] == secret
      render text: "To experience chaos, please set X-Chaos-Secret header", content_type: 'text/plain', status: 401
    end
  end
end
