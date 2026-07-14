# frozen_string_literal: true

module BitbucketServer
  module Representation
    class User < Representation::Base
      def email
        user['emailAddress']
      end

      def username
        user['slug']
      end

      private

      def user
        raw['user']
      end
    end
  end
end
