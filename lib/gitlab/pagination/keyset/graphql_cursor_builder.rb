# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      # Translates GraphQL pagination args (`after` / `before`) into a base64
      # keyset cursor with the direction marker that
      # Gitlab::Pagination::Keyset::Paginator expects.
      module GraphqlCursorBuilder
        Converter = Paginator::Base64CursorConverter
        FORWARD = Paginator::FORWARD_DIRECTION
        BACKWARD = Paginator::BACKWARD_DIRECTION

        def self.build(after: nil, before: nil)
          if after
            with_direction(after, FORWARD)
          elsif before
            with_direction(before, BACKWARD)
          end
        end

        def self.with_direction(cursor, direction)
          attrs = Converter.parse(cursor)
          attrs[:_kd] = direction
          Converter.dump(attrs)
        end
        private_class_method :with_direction
      end
    end
  end
end
