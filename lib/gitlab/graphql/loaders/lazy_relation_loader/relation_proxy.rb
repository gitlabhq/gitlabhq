# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class LazyRelationLoader
        # Proxies all the method calls to Registry instance.
        # The main purpose of having this is that calling load
        # on an instance of this class will only return the records
        # associated with the main Active Record model.
        class RelationProxy
          def initialize(object, registry)
            @object = object
            @registry = registry
          end

          def load
            registry.for(object)
          end
          alias_method :to_a, :load

          def last(limit = 1)
            result = registry.limit(limit)
                           .reverse_order!
                           .for(object)

            return result.first if limit == 1 # This is the Active Record behavior

            result
          end

          private

          attr_reader :registry, :object

          # Delegate everything to registry
          def method_missing(method_name, ...)
            result = registry.public_send(method_name, ...) # rubocop:disable GitlabSecurity/PublicSend

            return self if result == registry

            result
          end

          def respond_to_missing?(method_name, include_private = false)
            registry.respond_to?(method_name, include_private)
          end
        end
      end
    end
  end
end
