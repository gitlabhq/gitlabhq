module Github
  module Representation
    class User < Representation::Base
      def id
        raw['id']
      end

      def email
        return @email if defined?(@email)

        @email = Github::User.new(username, options).get.fetch('email', nil)
      end

      def username
        raw['login']
      end
    end
  end
end
