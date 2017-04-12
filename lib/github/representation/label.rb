module Github
  module Representation
    class Label < Representation::Base
      def color
        "##{raw['color']}"
      end

      def title
        raw['name']
      end

      def url
        raw['url']
      end
    end
  end
end
