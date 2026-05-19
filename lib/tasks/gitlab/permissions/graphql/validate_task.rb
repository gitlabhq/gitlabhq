# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Graphql
        class ValidateTask < ::Tasks::Gitlab::Permissions::BaseValidateTask
          def initialize
            @violations = {
              boundary_mismatch: [],
              invalid_permission: []
            }
          end

          private

          attr_reader :violations

          def validate!
            each_directive do |item, directive|
              permissions = directive.arguments[:permissions].map { |p| p.to_s.downcase.to_sym }
              boundary_type = directive.arguments[:boundary_type]&.to_sym

              permissions.each do |permission|
                validate_permission_exists(item, permission)
                validate_boundary_type(item, permission, boundary_type)
              end
            end

            super
          end

          def each_directive(&block)
            each_type_directive(&block)
            each_mutation_directive(&block)
            each_field_directive(&block)
          end

          def each_type_directive
            GitlabSchema.types.each do |name, type|
              next unless graphql_object_type?(name, type)

              type.directives.each do |directive|
                next unless directive.is_a?(Directives::Authz::GranularScope)

                yield({ kind: 'type', name: name, source: class_source_path(type) }, directive)
              end
            end
          end

          def each_mutation_directive
            GitlabSchema.types['Mutation'].fields.each do |field_name, field|
              resolver = resolve_mutation_class(field)
              next unless resolver

              mutation_name = resolver.respond_to?(:graphql_name) ? resolver.graphql_name : field_name.camelize
              find_mutation_directives(field, resolver).each do |directive|
                yield({ kind: 'mutation', name: mutation_name, source: class_source_path(resolver) }, directive)
              end
            end
          end

          def each_field_directive
            GitlabSchema.types.each do |type_name, type|
              next if type_name == 'Mutation'
              next unless type.respond_to?(:fields)

              type.fields.each do |field_name, field|
                next unless field.respond_to?(:directives)

                field.directives.each do |directive|
                  next unless directive.is_a?(Directives::Authz::GranularScope)

                  yield({ kind: 'field', name: "#{type_name}.#{field_name}",
                          source: class_source_path(type) }, directive)
                end
              end
            end
          end

          def graphql_object_type?(name, type)
            # Skip introspection types (__Schema, __Type, __Field, etc.)
            return false if name.start_with?('__')

            type.kind.object? && !name.end_with?('Payload', 'Connection', 'Edge')
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
            directives = if field.respond_to?(:directives)
                           field.directives.select { |d| d.is_a?(Directives::Authz::GranularScope) }
                         else
                           []
                         end

            if directives.empty? && resolver.respond_to?(:directives)
              directives = resolver.directives.select { |d| d.is_a?(Directives::Authz::GranularScope) }
            end

            directives
          end

          def valid_permissions
            @valid_permissions ||= Authz::PermissionGroups::Assignable.available_permissions.to_set
          end

          def validate_permission_exists(item, permission)
            return if valid_permissions.include?(permission)

            violations[:invalid_permission] << item.merge(permission: permission)
          end

          def validate_boundary_type(item, permission, boundary_type)
            return unless boundary_type

            assignables = Authz::PermissionGroups::Assignable.available_for_permission(permission)
            return if assignables.empty?

            assignable_boundaries = assignables.flat_map(&:boundaries).uniq.map(&:to_sym)
            return if assignable_boundaries.include?(boundary_type)

            violations[:boundary_mismatch] << item.merge(
              permission: permission,
              boundary_type: boundary_type,
              assignable_boundaries: assignable_boundaries
            )
          end

          def format_all_errors
            format_graphql_errors(:invalid_permission) + format_boundary_mismatch_errors
          end

          def format_graphql_errors(kind)
            return '' if violations[kind].empty?

            out = "#{error_messages[kind]}\n\n"

            violations[kind].each do |v|
              out += "  - [#{v[:kind]}] #{v[:name]}: #{v[:permission]} (#{v[:source]})\n"
            end

            "#{out}\n"
          end

          def format_boundary_mismatch_errors
            return '' if violations[:boundary_mismatch].empty?

            out = "#{error_messages[:boundary_mismatch]}\n\n"

            violations[:boundary_mismatch].each do |v|
              out += "  - [#{v[:kind]}] #{v[:name]}: #{v[:permission]} (#{v[:source]})\n"
              out += "      Directive boundary_type: #{v[:boundary_type]}\n"
              out += "      Assignable boundaries: #{v[:assignable_boundaries].join(', ')}\n"
            end

            "#{out}\n"
          end

          def class_source_path(klass)
            file, _line = Object.const_source_location(klass.name)
            relative_path(file)
          end

          def error_messages
            {
              invalid_permission: <<~MSG.chomp,
                The following GraphQL types/mutations/fields reference permissions not included in any assignable permission.
                Add the permission to an assignable permission group in config/authz/permission_groups/assignable_permissions/.
                #{assignable_permissions_link(anchor: 'create-the-assignable-permission-file')}
              MSG
              boundary_mismatch: <<~MSG.chomp
                The following GraphQL types/mutations/fields have a boundary_type that doesn't match the assignable permission boundaries.
                Update the assignable permission to include the directive's boundary_type, or fix the directive's boundary_type.
                #{assignable_permissions_link(anchor: 'determining-boundaries')}
              MSG
            }
          end

          def print_success_message
            puts "GraphQL permissions are valid"
          end

          def json_schema_file
            nil
          end
        end
      end
    end
  end
end
