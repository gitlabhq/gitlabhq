# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class ClientMiddleware
      def call(_, job, _, _)
        status_expiration = job['status_expiration']

        unless ::Feature.enabled?(:opt_in_sidekiq_status, default_enabled: :yaml)
          status_expiration ||= Gitlab::SidekiqStatus::DEFAULT_EXPIRATION
        end

        Gitlab::SidekiqStatus.set(job['jid'], status_expiration)

        yield
      end
    end
  end
end
