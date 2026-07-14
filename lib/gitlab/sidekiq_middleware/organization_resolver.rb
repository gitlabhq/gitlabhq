# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    # Resolves the Organizations::Organization for a given Sidekiq job.
    #
    # Given a (worker_class, args) pair, returns one of:
    #   - An Organizations::Organization instance: the job is scoped to exactly one org
    #   - :cross_org: the job intentionally spans multiple orgs
    #   - :unresolved: the org cannot be determined from the args
    #
    # ## Design rationale
    #
    # ApplicationContext serialises context *into* job payloads (e.g. organization_id => org.id)
    # via `to_lazy_hash`, but it never reads models back out from args at execution time.
    # The only mechanism that derives context from job['args'] today is the per-worker opt-in
    # `worker_class.context_for_arguments(job['args'])` / Gitlab::BatchWorkerContext.
    #
    # Rather than extending ApplicationContext to rehydrate objects (which would couple the
    # context layer to model loading), we standardise on a new per-worker opt-in method
    # `organization_for_arguments(args)` that mirrors `context_for_arguments`. Workers that
    # already know their org (e.g. because they receive an organization_id argument) implement
    # this method and return the appropriate value. Workers that do not implement it return
    # :unresolved, which is the safe default for the first iteration.
    #
    # This is the foundational piece for the Sidekiq read-only mode track. It is intentionally
    # not wired into any middleware yet -- that is tracked separately.
    #
    # ## Naming note
    #
    # The class lives under Gitlab::SidekiqMiddleware (rather than Gitlab::Sidekiq) to avoid
    # shadowing the top-level Sidekiq gem constant inside the Gitlab module, which would break
    # unqualified references such as `Sidekiq.server?` in lib/gitlab/marginalia.rb and others.
    #
    # @see https://gitlab.com/gitlab-org/gitlab/-/work_items/602815
    class OrganizationResolver
      # Sentinel returned when a job intentionally spans multiple organizations
      # (e.g. a cron job that iterates all orgs).
      CROSS_ORG = :cross_org

      # Sentinel returned when the organization cannot be determined from the
      # worker class and its arguments.
      UNRESOLVED = :unresolved

      # Resolves the organization for the given worker class and arguments.
      #
      # @param worker_class [Class] the Sidekiq worker class (must include ApplicationWorker)
      # @param args [Array] the raw Sidekiq job arguments
      # @return [Organizations::Organization, :cross_org, :unresolved]
      def self.resolve(worker_class, args)
        new(worker_class, args).resolve
      end

      # @param worker_class [Class]
      # @param args [Array]
      def initialize(worker_class, args)
        @worker_class = worker_class
        @args = args
      end

      # Exceptions raised by the worker's #organization_for_arguments (e.g.
      # ActiveRecord::RecordNotFound) are intentionally not rescued: they
      # propagate to the caller so Sidekiq can apply its normal retry handling.
      #
      # @return [Organizations::Organization, :cross_org, :unresolved]
      def resolve
        return UNRESOLVED unless worker_class.respond_to?(:organization_for_arguments)

        worker_class.organization_for_arguments(args).tap { |result| validate_result!(result) }
      end

      private

      attr_reader :worker_class, :args

      # Validates that the worker returned a value of the correct type.
      #
      # @param result [Object]
      # @raise [ArgumentError] if the result is not a valid return value
      # @return [void]
      def validate_result!(result)
        return if result.is_a?(::Organizations::Organization)
        return if result == CROSS_ORG
        return if result == UNRESOLVED

        raise ArgumentError,
          "#{worker_class}#organization_for_arguments must return an " \
            "Organizations::Organization, :cross_org, or :unresolved, " \
            "got: #{result.inspect}"
      end
    end
  end
end
