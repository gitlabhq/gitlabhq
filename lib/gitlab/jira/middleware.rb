module Gitlab
  module Jira
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        env['HTTP_AUTHORIZATION'].sub!('token', 'Bearer') if jira_dvcs_connector?(env)

        @app.call(env)
      end

      private

      def jira_dvcs_connector?(env)
        /JIRA DVCS Connector/.match(env['HTTP_USER_AGENT'])
      end
    end
  end
end
