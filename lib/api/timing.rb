require_dependency 'gitlab/metrics/client_performance_stats'

module API
  # Timing access API
  class Timing < Grape::API
    helpers ::API::Helpers::InternalHelpers
    helpers ::Gitlab::Identifier

    namespace 'timing' do

      post "/stats" do
        Gitlab::Metrics::ClientPerformanceStats.record_browser_stats(
          connect: params[:connect],
          domainLookup: params[:domainLookup],
          request: params[:request],
          requestTtfb: params[:requestTtfb],
          interactive: params[:interactive],
          contentComplete: params[:contentComplete],
          loaded: params[:loaded],
        )

        status 200
      end
    end
  end
end
