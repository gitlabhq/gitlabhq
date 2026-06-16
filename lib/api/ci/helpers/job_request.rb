# frozen_string_literal: true

module API
  module Ci
    module Helpers
      # Shared request parameters and job-acquisition flow for the runner job
      # request endpoint (API::Ci::Runner) and the internal Job Router job request
      # endpoint (API::Internal::Ci::JobRouter). KAS forwards the runner's request
      # body verbatim to the latter, so both must accept the same parameters and run
      # the same acquisition logic. The response presentation and authentication are
      # intentionally left to each endpoint.
      module JobRequest
        extend Grape::API::Helpers

        params :request_job_params do
          requires :token, type: String, desc: "Runner's authentication token"
          optional :system_id, type: String, desc: "Runner's system identifier"
          optional :last_update, type: String, desc: "Runner's queue last_update token"
          optional :info, type: Hash, desc: "Runner's metadata" do
            optional :name, type: String, desc: "Runner's name"
            optional :version, type: String, desc: "Runner's version"
            optional :revision, type: String, desc: "Runner's revision"
            optional :platform, type: String, desc: "Runner's platform"
            optional :architecture, type: String, desc: "Runner's architecture"
            optional :executor, type: String, desc: "Runner's executor"
            optional :features, type: Hash, desc: "Runner's features"
            optional :config, type: Hash, desc: "Runner's config" do
              optional :gpus, type: String, desc: 'GPUs enabled'
            end
            optional :labels, type: Hash, desc: "Runner's labels"
          end
          optional :session, type: Hash, desc: "Runner's session data" do
            optional :url, type: String, desc: "Session's url"
            optional :certificate, type: String, desc: "Session's certificate"
            optional :authorization, type: String, desc: "Session's authorization"
          end
        end

        # Runs the shared flow for assigning a queued job to the current runner.
        # Halts the request with 204 No Content or 409 Conflict as appropriate; on
        # success returns the Ci::RegisterJobService result for the caller to present.
        def acquire_ci_job!(runner_params)
          unless current_runner.active?
            header 'X-GitLab-Last-Update', current_runner.ensure_runner_queue_value
            no_content!
          end

          if current_runner.runner_queue_value_latest?(runner_params[:last_update])
            header 'X-GitLab-Last-Update', runner_params[:last_update]
            ::Gitlab::Metrics.add_event(:build_not_found_cached)
            no_content!
          end

          new_update = current_runner.ensure_runner_queue_value

          ::Ci::RegisterJobService.new(current_runner, current_runner_manager).execute(runner_params).tap do |result|
            unless result.valid?
              # We received a build that is invalid due to a concurrency conflict
              ::Gitlab::Metrics.add_event(:build_invalid)
              conflict!
            end

            unless result.build
              ::Gitlab::Metrics.add_event(:build_not_found)
              header 'X-GitLab-Last-Update', new_update
              no_content!
            end

            ::Gitlab::Metrics.add_event(:build_found)
          end
        end
      end
    end
  end
end
