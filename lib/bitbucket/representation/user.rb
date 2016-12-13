module Bitbucket
  module Representation
    class User < Representation::Base
      def username
        raw['username'] || 'Anonymous'
      end

      def uuid
        raw['uuid']
      end
    end
  end
end
