module Gitlab
  module Import
    class Result
      attr_reader :errors

      def initialize
        @errors = []
      end

      def success?
        errors.blank?
      end

      def failed?
        !success?
      end
    end
  end
end
