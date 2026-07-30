# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module Graphql
        module Mounter
          def mount_aggregation_engine(engine, **options, &block)
            options[:field_name] ||= :aggregation
            options[:types_prefix] ||= options[:field_name]

            field_options = {
              description: options[:description],
              null: true,
              resolver_method: :object,
              authorize: options[:authorize],
              resolver: Resolvers::Analytics::Aggregation::EngineResolver.build(engine, **options, &block)
            }
            field_options[:experiment] = options[:experiment] if options.key?(:experiment)

            if options[:granular_authorization_opts]
              field_options[:directives] = granular_scope_directive(**options[:granular_authorization_opts])
            end

            field options[:field_name], **field_options
          end
        end
      end
    end
  end
end
