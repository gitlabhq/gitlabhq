# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Probes
      class Collection
        attr_reader :checks

        # This accepts an array of objects implementing `:readiness`
        # that returns `::Gitlab::HealthChecks::Result`
        def initialize(*checks)
          @checks = checks
        end

        def execute
          readiness = probe_readiness
          success = all_succeeded?(readiness)

          Probes::Status.new(
            success ? 200 : 503,
            status(success).merge(payload(readiness))
          )
        rescue StandardError => e
          exception_payload = { message: "#{e.class} : #{e.message}" }

          Probes::Status.new(
            500,
            status(false).merge(exception_payload))
        end

        private

        def all_succeeded?(readiness)
          readiness.all? do |name, probes|
            probes.any?(&:success)
          end
        end

        def status(success)
          { status: success ? 'ok' : 'failed' }
        end

        def payload(readiness)
          readiness.transform_values do |probes|
            probes.map(&:payload)
          end
        end

        def probe_readiness
          checks
            .select(&:available?)
            .flat_map(&:readiness)
            .compact
            .group_by(&:name)
        end
      end
    end
  end
end
