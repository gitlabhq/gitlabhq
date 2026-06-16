# frozen_string_literal: true

module API
  module Internal
    module Ci
      class JobRouter < ::API::Base
        feature_category :continuous_integration
        urgency :low

        helpers ::API::Helpers::KasHelpers

        before do
          authenticate_gitlab_kas_request!
        end

        helpers do
          include ::Gitlab::Utils::StrongMemoize

          def current_runner
            token = headers[Gitlab::Kas::INTERNAL_API_AGENT_REQUEST_HEADER]

            load_balancer_stick_request(::Ci::Runner, :runner, token) if token

            ::Ci::Runner.find_by_token(token.to_s)
          end
          strong_memoize_attr :current_runner

          def check_runner_token!
            unauthorized! unless current_runner
          end
        end

        namespace 'internal' do
          namespace 'ci' do
            namespace 'agents' do
              namespace 'runner' do
                before do
                  check_runner_token!
                end

                desc 'Gets agent info for runner' do
                  detail 'Retrieves agent info for runner for the given token'
                  success code: 200
                  failure [
                    { code: 401, message: '401 Unauthorized' }
                  ]
                  tags %w[job_router runner]
                end
                route_setting :authentication
                route_setting :authorization, skip_granular_token_authorization: :kas_jwt_auth
                get '/info' do
                  status 200
                  {
                    runner_id: current_runner.id
                  }
                end
              end
            end

            namespace 'job_router' do
              namespace 'jobs' do
                helpers ::API::Ci::Helpers::Runner
                helpers ::API::Helpers::RateLimiter
                helpers ::API::Ci::Helpers::JobRequest

                desc 'Request a job for the Job Router' do
                  detail 'Internal endpoint used by GitLab Relay (KAS) to request a job on behalf of a runner.'
                  success code: 201, model: ::API::Entities::Ci::JobRouter::JobResponse, message: 'Job was scheduled'
                  failure [
                    { code: 204, message: 'No job for Runner' },
                    { code: 401, message: '401 Unauthorized' },
                    { code: 403, message: '403 Forbidden' },
                    { code: 409, message: '409 Conflict' },
                    { code: 501, message: '501 Not Implemented' }
                  ]
                  tags %w[jobs job_router]
                end
                params do
                  use :request_job_params
                end
                route_setting :authorization, skip_granular_token_authorization: :kas_jwt_auth
                post 'request' do
                  check_rate_limit!(:runner_jobs_request_api,
                    scope: [::Gitlab::CryptoHelper.sha256(params[:token])], user: nil)

                  authenticate_runner!(creation_state: :finished)

                  ensure_job_router_enabled_for_runner!(current_runner)

                  result = acquire_ci_job!(declared_params(include_missing: false))

                  status :created
                  present result.build_presented, with: ::API::Entities::Ci::JobRouter::JobResponse
                end
              end
            end
          end
        end
      end
    end
  end
end

API::Internal::Ci::JobRouter.prepend_mod_with('API::Internal::Ci::JobRouter')
