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

            field_options = {
              description: opts[:description],
              null: true,
              resolver_method: :object,
              authorize: opts[:authorize],
              resolver: Resolvers::Analytics::Aggregation::EngineResolver.build(engine, **opts, &block)
            }
            field_options[:experiment] = opts[:experiment] if opts.key?(:experiment)

            if opts[:granular_authorization_opts]
              field_options[:directives] = granular_scope_directive(**opts[:granular_authorization_opts])
            end

            field opts[:field_name], **field_options
          end
        end
      end
    end
  end
end
