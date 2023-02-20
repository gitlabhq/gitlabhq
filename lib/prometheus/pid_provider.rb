# frozen_string_literal: true

module Prometheus
  module PidProvider
    extend self

    def worker_id
      if Gitlab::Runtime.sidekiq?
        sidekiq_worker_id
      elsif Gitlab::Runtime.puma?
        puma_worker_id
      else
        unknown_process_id
      end
    end

    private

    def sidekiq_worker_id
      if worker = ENV['SIDEKIQ_WORKER_ID']
        "sidekiq_#{worker}"
      else
        'sidekiq'
      end
    end

    def puma_worker_id
      if matches = process_name.match(/puma.*cluster worker ([0-9]+):/)
        "puma_#{matches[1]}"
      elsif process_name.include?('puma')
        "puma_master"
      else
        unknown_process_id
      end
    end

    def unknown_process_id
      "process_#{Process.pid}"
    end

    def process_name
      $PROGRAM_NAME
    end
  end
end
