# frozen_string_literal: true

module Gitlab
  class RequestContext
    class << self
      def client_ip
        Gitlab::SafeRequestStore[:client_ip]
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      req = ActionDispatch::Request.new(env)

      Gitlab::SafeRequestStore[:client_ip] = req.ip

      @app.call(env)
    end
  end
end
