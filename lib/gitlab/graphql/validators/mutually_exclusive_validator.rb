# frozen_string_literal: true

module Gitlab
  module Graphql
    module Validators
      class MutuallyExclusiveValidator < GraphQL::Schema::Validator
        def initialize(mutually_exclusive_arg_names, **default_options)
          @mutually_exclusive_arg_names = mutually_exclusive_arg_names

          super(**default_options)
        end

        def validate(_object, _context, args)
          return unless args.slice(*@mutually_exclusive_arg_names).compact.size > 1

          arg_str = @mutually_exclusive_arg_names.map { |x| x.to_s.camelize(:lower) }.join(', ')
          "Only one of [#{arg_str}] arguments is allowed at the same time."
        end
      end
    end
  end
end
