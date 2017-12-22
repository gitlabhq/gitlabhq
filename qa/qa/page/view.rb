module QA
  module Page
    class View
      attr_reader :path, :elements

      def initialize(path, elements)
        @path = path
        @elements = elements
      end
    end
  end
end
