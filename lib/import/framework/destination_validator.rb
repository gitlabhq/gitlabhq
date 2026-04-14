# frozen_string_literal: true

module Import
  module Framework
    # This class was extracted from BulkImport to serve as a generic utility.
    # It still relies on exception classes in the BulkImport namespace, which
    # we can make generic in a future change.
    class DestinationValidator
      def initialize(current_user:)
        @current_user = current_user
      end

      def validate!(destination_namespace, destination_slug, destination_name, source_type)
        validate_destination_namespace!(destination_namespace, source_type)
        validate_destination_slug!(destination_slug || destination_name)
        validate_destination_full_path!(destination_namespace, destination_slug, destination_name, source_type)
      end

      def validate_destination_namespace!(destination_namespace, source_type)
        return if destination_namespace.blank?

        group = Group.find_by_full_path(destination_namespace)
        if group.nil? ||
            (source_type == ::BulkImports::Entity::GROUP_ENTITY_SOURCE_TYPE &&
              !current_user.can?(:create_subgroup, group)) ||
            (source_type == ::BulkImports::Entity::PROJECT_ENTITY_SOURCE_TYPE &&
              !current_user.can?(:import_projects, group))
          raise ::BulkImports::Error.destination_namespace_validation_failure(destination_namespace)
        end
      end

      def validate_destination_slug!(destination_slug)
        return if Gitlab::Regex.oci_repository_path_regex.match?(destination_slug)

        raise ::BulkImports::Error.destination_slug_validation_failure
      end

      def validate_destination_full_path!(destination_namespace, destination_slug, destination_name, source_type)
        full_path = [
          destination_namespace,
          destination_slug || destination_name
        ].reject(&:blank?).join('/')

        case source_type
        when ::BulkImports::Entity::GROUP_ENTITY_SOURCE_TYPE
          return if Namespace.find_by_full_path(full_path).nil?
        when ::BulkImports::Entity::PROJECT_ENTITY_SOURCE_TYPE
          return if Project.find_by_full_path(full_path).nil?
        else
          raise ArgumentError, 'source_type must be one of group_entity, project_entity'
        end

        raise ::BulkImports::Error.destination_full_path_validation_failure(full_path)
      end

      private

      attr_reader :current_user
    end
  end
end
