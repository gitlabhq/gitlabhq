# frozen_string_literal: true

module Gitlab
  module Graphql
    module Validators
      class AtLeastOneOfValidator < GraphQL::Schema::Validator
        def initialize(at_least_one_of_arg_names, **default_options)
          @at_least_one_of_arg_names = at_least_one_of_arg_names

          super(**default_options)
        end

        def validate(_object, _context, args)
          return if args.slice(*@at_least_one_of_arg_names).compact.size >= 1

          arg_str = @at_least_one_of_arg_names.map { |x| x.to_s.camelize(:lower) }.join(', ')
          "At least one of [#{arg_str}] arguments is required."
        end
      end
    end
  end
end
