# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Assignable
        class ValidateTask < ::Tasks::Gitlab::Permissions::BaseValidateTask
          PERMISSION_DIR = ::Authz::PermissionGroups::Assignable::BASE_PATH

          def initialize
            @violations = {
              schema: {},
              duplicate_name: [],
              duplicate_raw_permission: {},
              file: {},
              missing_resource_metadata: [],
              resource_metadata_schema: {},
              category_metadata_schema: {},
              empty_resource_directory: [],
              empty_category_directory: []
            }
            @resources = []
            @categories = []
          end

          private

          attr_reader :violations, :resources, :categories

          def validate!
            defined_permissions = ::Authz::PermissionGroups::Assignable.all.values
            defined_permissions.each { |p| validate_permission(p) }

            validate_names
            validate_raw_permissions
            validate_resources
            validate_categories
            validate_empty_resource_directories
            validate_empty_category_directories

            super
          end

          def validate_permission(permission)
            validate_schema(permission)
            validate_file(permission)

            # Collect unique resources and categories for metadata validation
            return unless permission.category.present? && permission.resource.present?

            @resources << { category: permission.category, resource: permission.resource }
            @categories << permission.category
          end

          def validate_file(permission)
            expected_file_path_data = expected_file_path_data(permission)

            return if permission.source_file.match?(expected_file_path_data[:pattern])

            name_and_actual_path = "#{permission.name} in #{expected_file_path_data[:actual_path]}"
            violations[:file][name_and_actual_path] = expected_file_path_data[:expected]
          end

          def validate_names
            names = []

            Dir.glob(::Authz::PermissionGroups::Assignable.config_path).each do |path|
              yml = YAML.safe_load(File.read(path)).deep_symbolize_keys!
              names << yml[:name]
            end

            with_duplicates = names.tally.select { |_, count| count > 1 }.keys
            violations[:duplicate_name] = with_duplicates
          end

          def validate_raw_permissions
            duplicates = ::Authz::PermissionGroups::Assignable.all_permissions.filter_map do |raw_permission|
              assignables = ::Authz::PermissionGroups::Assignable.for_permission(raw_permission)
              [raw_permission, assignables.map(&:name)] if assignables.size > 1
            end.to_h

            violations[:duplicate_raw_permission] = duplicates
          end

          def validate_resources
            resources.uniq.each do |resource_data|
              category = resource_data[:category]
              resource = resource_data[:resource]

              resource_identifier = "#{category}/#{resource}"
              assignable_resource = ::Authz::PermissionGroups::Resource.get(resource_identifier)

              unless assignable_resource
                violations[:missing_resource_metadata] <<
                  "#{PERMISSION_DIR}/#{category}/#{resource}/"
                next
              end

              @resource_metadata_schema_validator ||= JSONSchemer.schema(
                Rails.root.join("#{PERMISSION_DIR}/resource_metadata_schema.json")
              )

              errors = @resource_metadata_schema_validator.validate(assignable_resource.definition)
              violations[:resource_metadata_schema][resource_identifier] = errors if errors.any?
            end
          end

          def validate_categories
            categories.uniq.each do |category_name|
              category = ::Authz::PermissionGroups::Category.get(category_name)
              next unless category

              @category_metadata_schema_validator ||= JSONSchemer.schema(
                Rails.root.join("#{PERMISSION_DIR}/category_metadata_schema.json")
              )

              errors = @category_metadata_schema_validator.validate(category.definition)
              violations[:category_metadata_schema][category_name] = errors if errors.any?
            end
          end

          def validate_empty_resource_directories
            # Check resource directories (inside category directories) for having only _metadata.yml
            violations[:empty_resource_directory] = find_empty_directories("#{PERMISSION_DIR}/*/*/")
          end

          def validate_empty_category_directories
            # Check category directories for having only _metadata.yml with no resource subdirectories
            violations[:empty_category_directory] = find_empty_parent_directories("#{PERMISSION_DIR}/*/")
          end

          def expected_file_path_data(permission)
            source_file = permission.source_file
            actual_path = source_file.slice(source_file.index(PERMISSION_DIR)..)

            category_regex = "([a-zA-Z_]+/){1}"
            pattern = Regexp.new(
              "#{PERMISSION_DIR}/#{category_regex}#{permission.resource}/#{permission.action}\.yml$"
            )

            category = permission.category.presence || '<category>'
            resource = permission.resource.presence || '<resource>'
            expected = "Expected path: #{PERMISSION_DIR}/#{category}/#{resource}/#{permission.action}.yml"

            { expected: expected, actual_path: actual_path, pattern: pattern }
          end

          def format_all_errors
            out = format_schema_errors
            out += format_error_list(:duplicate_name)
            out += format_duplicate_raw_permission_errors
            out += format_file_errors
            out += format_error_list(:missing_resource_metadata)
            out += format_schema_errors(:resource_metadata_schema)
            out += format_schema_errors(:category_metadata_schema)
            out += format_error_list(:empty_resource_directory)
            out + format_error_list(:empty_category_directory)
          end

          def format_duplicate_raw_permission_errors
            return '' if violations[:duplicate_raw_permission].empty?

            out = "#{error_messages[:duplicate_raw_permission]}\n\n"

            violations[:duplicate_raw_permission].keys.sort.each do |raw_permission|
              assignable_names = violations[:duplicate_raw_permission][raw_permission]
              out += "  - #{raw_permission}: found in #{assignable_names.sort.join(', ')}\n"
            end

            "#{out}\n"
          end

          def error_messages
            {
              schema: "The following permissions failed schema validation.",
              duplicate_name: "The following permissions have duplicate names." \
                "\nAssignable permissions must have unique names.",
              duplicate_raw_permission: "The following raw permissions are used in multiple assignable permissions." \
                "\nEach raw permission should only belong to one assignable permission.",
              file: "The following permission definitions do not exist at the expected path.",
              missing_resource_metadata:
                "The following assignable permission resource directories are missing a _metadata.yml file.",
              resource_metadata_schema:
                "The following assignable permission resource metadata file failed schema validation.",
              category_metadata_schema:
                "The following assignable permission category metadata file failed schema validation.",
              empty_resource_directory:
                "The following resource directories contain only a _metadata.yml file with no permission definitions." \
                "\nEither add permission definitions or remove the directory.",
              empty_category_directory:
                "The following category directories contain only a _metadata.yml file with no resource " \
                "subdirectories.\nEither add resource subdirectories or remove the directory."
            }
          end

          def print_success_message
            puts "Assignable permission definitions are up-to-date"
          end

          def json_schema_file
            Rails.root.join("#{PERMISSION_DIR}/type_schema.json")
          end
        end
      end
    end
  end
end
