# frozen_string_literal: true

module Gitlab
  module Graphql
    module MountMutation
      extend ActiveSupport::Concern

      class_methods do
        def mount_mutation(mutation_class, **custom_kwargs)
          # Using an underscored field name symbol will make `graphql-ruby`
          # standardize the field name
          field mutation_class.graphql_name.underscore.to_sym,
                mutation: mutation_class,
                **custom_kwargs
        end
      end
    end
  end
end
