module Gitlab
  module Badge
    class Base
      def key_text
        raise NotImplementedError
      end

      def value_text
        raise NotImplementedError
      end

      def metadata
        raise NotImplementedError
      end

      def template
        raise NotImplementedError
      end
    end
  end
end
