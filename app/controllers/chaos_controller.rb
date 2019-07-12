# frozen_string_literal: true

class ChaosController < ActionController::Base
  before_action :validate_chaos_secret, unless: :development?
  before_action :request_start_time

  def leakmem
    retainer = []
    # Add `n` 1mb chunks of memory to the retainer array
    memory_mb.times { retainer << "x" * 1.megabyte }

    Kernel.sleep(duration_left)

    render plain: "OK"
  end

  def cpu_spin
    rand while Time.now < expected_end_time

    render plain: "OK"
  end

  def db_spin
    while Time.now < expected_end_time
      ActiveRecord::Base.connection.execute("SELECT 1")

      end_interval_time = Time.now + [duration_s, interval_s].min
      rand while Time.now < end_interval_time
    end
  end

  def sleep
    Kernel.sleep(duration_left)

    render plain: "OK"
  end

  def kill
    Process.kill("KILL", Process.pid)
  end

  private

  def request_start_time
    @start_time ||= Time.now
  end

  def expected_end_time
    request_start_time + duration_s
  end

  def duration_left
    # returns 0 if over time
    [expected_end_time - Time.now, 0].max
  end

  def validate_chaos_secret
    unless chaos_secret_configured
      render plain: "chaos misconfigured: please configure GITLAB_CHAOS_SECRET",
             status: :internal_server_error
      return
    end

    unless Devise.secure_compare(chaos_secret_configured, chaos_secret_request)
      render plain: "To experience chaos, please set a valid `X-Chaos-Secret` header or `token` param",
             status: :unauthorized
      return
    end
  end

  def chaos_secret_configured
    ENV['GITLAB_CHAOS_SECRET']
  end

  def chaos_secret_request
    request.headers["HTTP_X_CHAOS_SECRET"] || params[:token]
  end

  def interval_s
    interval_s = params[:interval_s] || 1
    interval_s.to_f.seconds
  end

  def duration_s
    duration_s = params[:duration_s] || 30
    duration_s.to_i.seconds
  end

  def memory_mb
    memory_mb = params[:memory_mb] || 100
    memory_mb.to_i
  end

  def development?
    Rails.env.development?
  end
end
