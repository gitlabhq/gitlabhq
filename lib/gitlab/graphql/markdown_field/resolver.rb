# frozen_string_literal: true

module Gitlab
  module Graphql
    module MarkdownField
      class Resolver
        attr_reader :method_name

        def initialize(method_name)
          @method_name = method_name
        end

        def proc
          -> (object, _args, ctx) do
            # We need to `dup` the context so the MarkdownHelper doesn't modify it
            ::MarkupHelper.markdown_field(object, method_name, ctx.to_h.dup)
          end
        end
      end
    end
  end
end
