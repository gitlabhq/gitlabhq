# frozen_string_literal: true

module Gitlab
  module Graphql
    module MountMutation
      extend ActiveSupport::Concern

      module ClassMethods
        def mount_mutation(mutation_class)
          # Using an underscored field name symbol will make `graphql-ruby`
          # standardize the field name
          field mutation_class.graphql_name.underscore.to_sym,
                mutation: mutation_class
        end
      end
    end
  end
end
