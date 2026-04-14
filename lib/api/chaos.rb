# frozen_string_literal: true

module API
  # Internal chaos endpoint used to demonstrate feature flag observability.
  #
  # When the `ebonet_chaos_tests` feature flag is enabled for a randomly selected
  # project, this endpoint intentionally introduces failures (20% chance of HTTP 500)
  # or latency (20% chance of 300ms delay). When the flag is disabled, the endpoint
  # always returns successfully. This allows comparison of request metrics in Kibana
  # with the flag on vs. off.
  #
  # Access to this endpoint is gated by the `ebonet_chaos_endpoint_access` feature
  # flag, which can be enabled per-user on any environment (e.g. staging).
  #
  # This endpoint is temporary and will be removed once the observability example
  # has been demonstrated.
  class Chaos < ::API::Base
    before do
      authenticate!
      forbidden! unless Feature.enabled?(:ebonet_chaos_endpoint_access, current_user)
    end

    feature_category :feature_flags
    urgency :low

    namespace :chaos do
      desc 'Chaos test endpoint for feature flag observability' do
        detail <<~DESC
          Picks a project by random ID and checks the `ebonet_chaos_tests` feature flag.
          When enabled, introduces a 20% chance of a 500 error and a 20% chance of
          a 300ms delay. Returns 200 OK otherwise.
        DESC
        success code: 200, message: 'OK'
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 500, message: 'Internal Server Error (chaos-induced)' }
        ]
        tags %w[chaos]
      end
      route_setting :authorization, skip_granular_token_authorization: :internal_testing
      get :test do
        # Fetch a random project to use as the feature flag actor.
        # The project itself is not used beyond checking the flag.
        project = Project.offset(rand(Project.count)).first # rubocop:disable CodeReuse/ActiveRecord -- intentional direct AR use for chaos testing

        ::Gitlab::Chaos.feature_flag_test(self) if project && Feature.enabled?(:ebonet_chaos_tests, project)

        { status: 'ok' }
      end
    end
  end
end
