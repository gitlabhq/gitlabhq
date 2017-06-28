module Github
  module Representation
    class Release < Representation::Base
      def description
        raw['body']
      end

      def tag
        raw['tag_name']
      end

      def valid?
        !raw['draft']
      end
    end
  end
end
