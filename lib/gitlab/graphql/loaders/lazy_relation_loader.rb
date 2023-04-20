# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class LazyRelationLoader
        class << self
          attr_accessor :model, :association

          # Automatically register the inheriting
          # classes to GitlabSchema as lazy objects.
          def inherited(klass)
            GitlabSchema.lazy_resolve(klass, :load)
          end
        end

        def initialize(query_ctx, object, **kwargs)
          @query_ctx = query_ctx
          @object = object
          @kwargs = kwargs

          query_ctx[loader_cache_key] ||= Registry.new(relation(**kwargs))
          query_ctx[loader_cache_key].register(object)
        end

        # Returns an instance of `RelationProxy` for the object (parent model).
        # The returned object behaves like an Active Record relation to support
        # keyset pagination.
        def load
          case reflection.macro
          when :has_many
            relation_proxy
          when :has_one
            relation_proxy.last
          else
            raise 'Not supported association type!'
          end
        end

        private

        attr_reader :query_ctx, :object, :kwargs

        delegate :model, :association, to: :"self.class"

        # Implement this one if you want to filter the relation
        def relation(**)
          base_relation
        end

        def loader_cache_key
          @loader_cache_key ||= self.class.name.to_s + kwargs.sort.to_s
        end

        def base_relation
          placeholder_record.association(association).scope
        end

        # This will only work for HasMany and HasOne associations for now
        def placeholder_record
          model.new(reflection.active_record_primary_key => 0)
        end

        def reflection
          model.reflections[association.to_s]
        end

        def relation_proxy
          RelationProxy.new(object, query_ctx[loader_cache_key])
        end
      end
    end
  end
end
