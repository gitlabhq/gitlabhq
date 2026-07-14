# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      # Extracts boundary objects from `authorize_granular_token` directives.
      # Directives with `boundary_argument` read from the field or mutation
      # arguments; all other directives read from the resolved object.
      class BoundaryExtractor
        STANDALONE_BOUNDARIES = [:user, :instance].freeze
        ITSELF = :itself

        def initialize(directives, object:, arguments:)
          @directives = directives
          @object = object
          @arguments = arguments
        end

        # Concrete (project/group) boundaries take precedence over
        # standalone (:user/:instance) boundaries.
        def extract
          concrete = []
          standalone = []

          directives.each do |directive|
            if standalone?(directive)
              standalone << boundary_type(directive)
            else
              resource = concrete_resource(directive)
              concrete << resource if resource && matches_boundary_type?(directive, resource)
            end
          end

          return concrete.uniq if concrete.any?

          standalone.uniq
        end

        private

        attr_reader :directives

        def concrete_resource(directive)
          if directive.arguments[:boundary_argument]
            resource_from_arguments(directive)
          else
            resource_from_object(directive)
          end
        end

        def resource_from_arguments(directive)
          return unless @arguments

          record = locate(@arguments[directive.arguments[:boundary_argument].to_sym])
          return unless record
          return record if record.is_a?(::Project) || record.is_a?(::Group)

          method_name = boundary_method(directive)
          return unless method_name

          record.try(method_name)
        end

        def resource_from_object(directive)
          return if @object.nil?

          method_name = boundary_method(directive)
          return @object if method_name == ITSELF
          return unless method_name

          @object.try(method_name)
        end

        def locate(value)
          case value
          when GlobalID then ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(value))
          when String then ::Project.find_by_full_path(value) || ::Group.find_by_full_path(value)
          end
        rescue ActiveRecord::RecordNotFound
          nil
        end

        # The same `boundary` method can resolve to different types
        # (e.g. `runner.owner` is a Project, Group, or User), so skip directives
        # whose resolved object isn't the declared `boundary_type`.
        def matches_boundary_type?(directive, resource)
          return false if resource.nil?

          resource.class.name.underscore == boundary_type(directive).to_s
        end

        def standalone?(directive)
          STANDALONE_BOUNDARIES.include?(boundary_type(directive))
        end

        def boundary_type(directive)
          directive.arguments[:boundary_type]&.to_sym
        end

        def boundary_method(directive)
          directive.arguments[:boundary]&.to_sym
        end
      end
    end
  end
end
