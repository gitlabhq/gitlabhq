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
              file: {}
            }
          end

          private

          attr_reader :violations

          def validate!
            defined_permissions = ::Authz::PermissionGroups::Assignable.all.values
            defined_permissions.each { |p| validate_permission(p) }

            validate_names

            super
          end

          def validate_permission(permission)
            validate_schema(permission)
            validate_file(permission)
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
            out + format_file_errors
          end

          def error_messages
            {
              schema: "The following permissions failed schema validation.",
              duplicate_name: "The following permissions have duplicate names." \
                "\nAssignable permissions must have unique names.",
              file: "The following permission definitions do not exist at the expected path."
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
