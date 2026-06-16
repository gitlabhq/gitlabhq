# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Graphql
        # Walks the GraphQL schema for `GranularScope` directives on types,
        # mutations, and fields. Shared by ValidateTask (which reports on them)
        # and DocsTask (which documents them).
        #
        # `each_granular_directive` yields `[{ kind:, name:, source: }, directive]`
        # for every directive found, where `kind` is `'type'`, `'mutation'`, or
        # `'field'`.
        module SchemaDirectives
          def each_granular_directive(&block)
            each_type_directive(&block)
            each_mutation_directive(&block)
            each_field_directive(&block)
          end

          private

          def each_type_directive
            GitlabSchema.types.each do |name, type|
              next unless graphql_object_type?(name, type)

              granular_directives(type).each do |directive|
                yield({ kind: 'type', name: name, source: class_source_path(type) }, directive)
              end
            end
          end

          def each_mutation_directive
            GitlabSchema.types['Mutation'].fields.each do |field_name, field|
              resolver = resolve_mutation_class(field)
              next unless resolver

              name = mutation_name_for(field_name, resolver)
              find_mutation_directives(field, resolver).each do |directive|
                yield({ kind: 'mutation', name: name, source: class_source_path(resolver) }, directive)
              end
            end
          end

          def each_field_directive
            GitlabSchema.types.each do |type_name, type|
              next if type_name == 'Mutation'
              next unless type.respond_to?(:fields)

              type.fields.each do |field_name, field|
                next unless field.respond_to?(:directives)

                name = "#{type_name}.#{field_name}"
                granular_directives(field).each do |directive|
                  yield({ kind: 'field', name: name, source: class_source_path(type) }, directive)
                end
              end
            end
          end

          def granular_directives(item)
            item.directives.select { |d| d.is_a?(Directives::Authz::GranularScope) }
          end

          def graphql_object_type?(name, type)
            return false if name.start_with?('__')
            return false if %w[Mutation Query Subscription].include?(name)

            type.kind.object? && !name.end_with?('Payload', 'Connection', 'Edge')
          end

          def mutation_name_for(field_name, resolver)
            resolver.respond_to?(:graphql_name) ? resolver.graphql_name : field_name.camelize
          end

          # Resolves the mutation class from a field on the Mutation type.
          # GraphQL Ruby exposes the resolver differently depending on context:
          # - `resolver_class` is available on most field objects
          # - `resolver` and `mutation` are fallbacks for different GraphQL Ruby versions
          # Returns the resolver only if it's a BaseMutation subclass.
          def resolve_mutation_class(field)
            resolver = field.respond_to?(:resolver_class) ? field.resolver_class : nil
            resolver ||= field.respond_to?(:resolver) ? field.resolver : nil
            resolver ||= field.respond_to?(:mutation) ? field.mutation : nil
            resolver if resolver && resolver < Mutations::BaseMutation
          end

          def find_mutation_directives(field, resolver)
            directives = field.respond_to?(:directives) ? granular_directives(field) : []
            directives = granular_directives(resolver) if directives.empty? && resolver.respond_to?(:directives)
            directives
          end

          def class_source_path(klass)
            return unless klass.name

            file, _line = Object.const_source_location(klass.name)
            return unless file

            Pathname.new(file).relative_path_from(Rails.root).to_s
          end
        end
      end
    end
  end
end
