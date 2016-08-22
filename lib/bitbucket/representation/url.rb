module Bitbucket
  module Representation
    class Url < Representation::Base
      def to_s
        raw.dig('links', 'self', 'href')
      end
    end
  end
end
