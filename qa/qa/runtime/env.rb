module QA
  module Runtime
    module Env
      extend self

      # set to 'false' to have Chrome run visibly instead of headless
      def chrome_headless?
        (ENV['CHROME_HEADLESS'] =~ /^(false|no|0)$/i) != 0
      end

      def running_in_ci?
        ENV['CI'] || ENV['CI_SERVER']
      end

      # specifies token that can be used for the api
      def personal_access_token
        ENV['PERSONAL_ACCESS_TOKEN']
      end

      def user_username
        ENV['GITLAB_USERNAME']
      end

      def user_password
        ENV['GITLAB_PASSWORD']
      end

      def sandbox_name
        ENV['GITLAB_SANDBOX_NAME']
      end
    end
  end
end
