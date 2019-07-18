# frozen_string_literal: true

require 'prometheus/client/support/unicorn'

module Prometheus
  module PidProvider
    extend self

    def worker_id
      if Sidekiq.server?
        'sidekiq'
      elsif defined?(Unicorn::Worker)
        "unicorn_#{unicorn_worker_id}"
      elsif defined?(::Puma)
        "puma_#{puma_worker_id}"
      else
        "process_#{Process.pid}"
      end
    end

    private

    # This is not fully accurate as we don't really know if the nil returned
    # is actually means we're on master or not.
    # Follow up issue was created to address this problem and
    # to introduce more structrured approach to a current process discovery:
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/64740
    def unicorn_worker_id
      ::Prometheus::Client::Support::Unicorn.worker_id || 'master'
    end

    # See the comment for #unicorn_worker_id
    def puma_worker_id
      match = process_name.match(/cluster worker ([0-9]+):/)
      match ? match[1] : 'master'
    end

    def process_name
      $0
    end
  end
end
