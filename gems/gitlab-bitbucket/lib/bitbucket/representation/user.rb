# frozen_string_literal: true

module Bitbucket
  module Representation
    class User < Representation::Base
      def username
        raw['username']
      end

      def account_id
        user['account_id']
      end

      def name
        user['display_name']
      end

      def nickname
        user['nickname']
      end

      private

      def user
        raw['user']
      end
    end
  end
end
