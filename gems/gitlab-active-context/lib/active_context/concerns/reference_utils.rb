# frozen_string_literal: true

module ActiveContext
  module Concerns
    module ReferenceUtils
      def delimit(string)
        string.split(self::DELIMITER)
      end

      def args_to_hash(args)
        args.each_with_index.to_h { |arg, index| [:"arg#{index + 1}", arg] }
      end

      def join_delimited(array)
        [self, array].join(self::DELIMITER)
      end

      def deserialize_string(string)
        delimit(string)[1..]
      end

      def ref_klass(string)
        klass = delimit(string).first.safe_constantize

        klass if klass && klass < ::ActiveContext::Reference
      end

      def ref_module
        to_s.pluralize
      end
    end
  end
end
