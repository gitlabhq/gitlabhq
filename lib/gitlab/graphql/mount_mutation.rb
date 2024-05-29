# frozen_string_literal: true

module Gitlab
  module Graphql
    module MountMutation
      extend ActiveSupport::Concern

      class_methods do
        def mount_mutation(mutation_class, **custom_kwargs)
          custom_kwargs[:scopes] ||= [:api]

          # Using an underscored field name symbol will make `graphql-ruby`
          # standardize the field name

          field mutation_class.graphql_name.underscore.to_sym,
            mutation: mutation_class,
            **custom_kwargs
        end

        def mount_aliased_mutation(alias_name, mutation_class, **custom_kwargs)
          aliased_mutation_class = Class.new(mutation_class) do
            graphql_name alias_name
          end

          mount_mutation(aliased_mutation_class, **custom_kwargs)
        end
      end
    end
  end
end
