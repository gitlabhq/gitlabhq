# frozen_string_literal: true

module Gitlab
  module Audit
    class NullTarget
      def id
        nil
      end

      def type
        nil
      end

      def details
        nil
      end
    end
  end
end
