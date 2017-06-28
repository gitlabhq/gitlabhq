module Github
  module Representation
    class Label < Representation::Base
      def color
        "##{raw['color']}"
      end

      def title
        raw['name']
      end
    end
  end
end
