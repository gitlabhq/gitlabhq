# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Probes
      class Readiness
        attr_reader :checks

        # This accepts an array of Proc
        # that returns `::Gitlab::HealthChecks::Result`
        def initialize(*additional_checks)
          @checks = ::Gitlab::HealthChecks::CHECKS.map { |check| check.method(:readiness) }
          @checks += additional_checks
        end

        def execute
          readiness = probe_readiness
          success = all_succeeded?(readiness)

          Probes::Status.new(
            success ? 200 : 503,
            status(success).merge(payload(readiness))
          )
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
            .flat_map(&:call)
            .compact
            .group_by(&:name)
        end
      end
    end
  end
end
