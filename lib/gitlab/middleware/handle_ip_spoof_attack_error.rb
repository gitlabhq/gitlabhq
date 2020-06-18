# frozen_string_literal: true

module Gitlab
  module Middleware
    # ActionDispatch::RemoteIp tries to set the `request.ip` for controllers by
    # looking at the request IP and headers. It needs to see through any reverse
    # proxies to get the right answer, but there are some security issues with
    # that.
    #
    # Proxies can specify `Client-Ip` or `X-Forwarded-For`, and the security of
    # that is determined at the edge. If both headers are present, it's likely
    # that the edge is securing one, but ignoring the other. Rails blocks this,
    # which is correct, because we don't know which header is the safe one - but
    # we want the block to be a 400, rather than 500, error.
    #
    # This middleware needs to go before ActionDispatch::RemoteIp in the chain.
    class HandleIpSpoofAttackError
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        app.call(env)
      rescue ActionDispatch::RemoteIp::IpSpoofAttackError => err
        Gitlab::ErrorTracking.track_exception(err)

        [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']]
      end
    end
  end
end
