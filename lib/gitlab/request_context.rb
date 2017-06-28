module Gitlab
  class RequestContext
    class << self
      def client_ip
        RequestStore[:client_ip]
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)

      RequestStore[:client_ip] = req.ip

      @app.call(env)
    end
  end
end
