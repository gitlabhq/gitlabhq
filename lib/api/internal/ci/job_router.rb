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
                get '/info' do
                  status 200
                  {
                    runner_id: current_runner.id
                  }
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
