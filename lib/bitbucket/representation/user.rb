# frozen_string_literal: true

module Bitbucket
  module Representation
    class User < Representation::Base
      def username
        raw['username']
      end
    end
  end
end
