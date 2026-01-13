# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      # Extracts authorization boundary (Project/Group) from GraphQL field resolution
      #
      # Usage in authorization directives:
      # - `boundary_argument: 'arg_name'` - Extracts boundary from argument (GlobalID or full_path string)
      # - `boundary: 'method_name'` - Calls method on resolved object, or falls back to :id argument for query fields
      # - `boundary: 'user'` or `boundary: 'instance'` - For standalone resources without project/group boundaries
      class BoundaryExtractor
        STANDALONE_BOUNDARIES = %w[user instance].freeze
        VALID_BOUNDARY_ACCESSOR_METHODS = %w[project group itself].freeze

        def initialize(object:, arguments:, context:, directive:)
          @object = object
          @arguments = arguments
          @context = context
          @directive = directive
          @boundary_accessor = directive.arguments[:boundary]
        end

        def extract
          resource = standalone_boundary? ? @boundary_accessor.to_sym : extract_resource
          return if resource.nil?

          ::Authz::Boundary.for(resource)
        end

        private

        def standalone_boundary?
          STANDALONE_BOUNDARIES.include?(@boundary_accessor&.to_s)
        end

        def extract_resource
          # Extract from argument (for mutations/query fields)
          boundary_arg = @directive.arguments[:boundary_argument]
          return extract_from_argument(boundary_arg) if boundary_arg

          # Extract from resolved object (for type fields)
          if @boundary_accessor
            return extract_from_id_argument if should_use_id_fallback?

            return extract_from_method
          end

          nil
        end

        def extract_from_argument(arg_name)
          args = @arguments[:input] || @arguments
          arg_value = args[arg_name.to_sym]

          resolve_value(arg_value)
        end

        def extract_from_method
          obj = unwrap_object(@object)

          return obj if object_matches_boundary_type?(obj)

          unless VALID_BOUNDARY_ACCESSOR_METHODS.include?(@boundary_accessor.to_s)
            raise ArgumentError, "Invalid boundary method: '#{@boundary_accessor}'"
          end

          unless obj.respond_to?(@boundary_accessor.to_sym)
            raise ArgumentError, "Boundary method '#{@boundary_accessor}' not found on #{obj.class}"
          end

          obj.public_send(@boundary_accessor.to_sym) # rubocop:disable GitlabSecurity/PublicSend -- Safe: @boundary_accessor from directive config
        end

        def object_matches_boundary_type?(obj)
          # Check if the object's class name matches the boundary method
          # E.g., 'project' matches Project, 'group' matches Group
          obj.class.name.underscore == @boundary_accessor.to_s
        end

        def resolve_value(value)
          case value
          when GlobalID
            resolve_global_id(value)
          when String
            resolve_path(value)
          end
        end

        def resolve_global_id(global_id)
          return unless global_id

          object = GlobalID::Locator.locate(global_id)
          extract_boundary_from_object(object)
        rescue ActiveRecord::RecordNotFound
          nil
        end

        def resolve_path(path)
          ::Project.find_by_full_path(path) || ::Group.find_by_full_path(path)
        end

        def extract_boundary_from_object(object)
          obj = unwrap_object(object)

          return obj if obj.is_a?(::Project) || obj.is_a?(::Group)
          return obj.project if obj.respond_to?(:project)
          return obj.group if obj.respond_to?(:group)

          nil
        end

        def unwrap_object(object)
          object.is_a?(::Types::BaseObject) ? object.object : object
        end

        def should_use_id_fallback?
          # Use ID fallback when:
          # 1. Object is nil (query field before resolution)
          # 2. Object doesn't respond to the boundary method
          # 3. An :id argument is present (GlobalID)
          return false unless @arguments[:id]

          @object.nil? || !object_responds_to_boundary?
        end

        def object_responds_to_boundary?
          obj = unwrap_object(@object)
          obj.respond_to?(@boundary_accessor.to_sym)
        end

        def extract_from_id_argument
          # Extract boundary from :id GlobalID argument
          # This is used for query fields like issue(id: "gid://gitlab/Issue/123")
          # where the directive says boundary: 'project' but we don't have an issue yet
          id_arg = @arguments[:id]

          case id_arg
          when GlobalID
            resolve_global_id(id_arg)
          when String
            resolve_global_id(GlobalID.parse(id_arg))
          else
            raise ArgumentError, "ID argument must be a GlobalID or string"
          end
        end
      end
    end
  end
end
