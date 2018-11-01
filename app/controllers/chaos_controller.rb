# frozen_string_literal: true

class ChaosController < ActionController::Base
  def leakmem
    memory_mb = params[:memory_mb] ? params[:memory_mb].to_i : 100
    retainer = []

    memory_mb.times { retainer << "x" * (1024 * 1024) }
    render text: "OK", content_type: 'text/plain'
  end

  def cpuspin
    duration_s = params[:duration_s] ? params[:duration_s].to_i : 30
    end_time = Time.now + duration_s.seconds;
    while Time.now < end_time
      10_000.times { }
    end

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

end
