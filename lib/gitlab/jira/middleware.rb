module Gitlab
  module Jira
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless /JIRA DVCS Connector/.match(env['HTTP_USER_AGENT'])

        env['HTTP_AUTHORIZATION'] = env['HTTP_AUTHORIZATION'].sub('token', 'Bearer')

        @app.call(env)
      end
    end
  end
end
