# frozen_string_literal: true

module API
  module Entities
    module EntityHelpers
      def can_read(attr, &block)
        ->(obj, opts) { Ability.allowed?(opts[:user], "read_#{attr}".to_sym, yield(obj)) }
      end

      def can_destroy(attr, &block)
        ->(obj, opts) { Ability.allowed?(opts[:user], "destroy_#{attr}".to_sym, yield(obj)) }
      end

      def expose_restricted(attr, documentation: {}, &block)
        expose attr, documentation: documentation, if: can_read(attr, &block)
      end
    end
  end
end
