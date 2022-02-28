# frozen_string_literal: true

module Gitlab
  module Graphql
    class BatchKey
      attr_reader :object

      delegate :hash, to: :object

      def initialize(object, lookahead = nil, object_name: nil)
        @object = object
        @lookahead = lookahead
        @object_name = object_name
      end

      def requires?(path)
        return false unless @lookahead
        return false unless path.present?

        field = path.pop

        path
          .reduce(@lookahead) { |q, f| q.selection(f) }
          .selects?(field)
      end

      def eql?(other)
        other.is_a?(self.class) && object == other.object
      end
      alias_method :==, :eql?

      def method_missing(method_name, *args, **kwargs)
        return @object if method_name.to_sym == @object_name
        return @object.public_send(method_name) if args.empty? && kwargs.empty? # rubocop: disable GitlabSecurity/PublicSend

        super
      end
    end
  end
end
