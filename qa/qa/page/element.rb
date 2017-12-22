module QA
  module Page
    class Element
      attr_reader :name

      def initialize(name, pattern)
        @name = name
        @pattern = pattern
      end
    end
  end
end
