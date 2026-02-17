# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module Graphql
        module Mounter
          def mount_aggregation_engine(engine, **options, &block)
            opts = options
            opts[:field_name] ||= :aggregation
            opts[:types_prefix] ||= opts[:field_name]

            field opts[:field_name],
              description: opts[:description],
              null: true,
              resolver_method: :object,
              resolver: Resolvers::Analytics::Aggregation::EngineResolver.build(engine, **opts, &block)
          end
        end
      end
    end
  end
end
