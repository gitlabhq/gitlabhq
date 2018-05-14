module Peek
  module Views
    class Host < View
      def results
        { hostname: Gitlab::Environment.hostname }
      end
    end
  end
end
