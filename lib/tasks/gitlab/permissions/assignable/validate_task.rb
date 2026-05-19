# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Assignable
        class ValidateTask < ::Tasks::Gitlab::Permissions::BaseValidateTask
          PERMISSION_DIR = ::Authz::PermissionGroups::Assignable::BASE_PATH
          PERMISSION_NAME_REGEX = ::Authz::Validation::PERMISSION_NAME_REGEX
          DISALLOWED_ACTIONS = ::Authz::Validation::DISALLOWED_ACTIONS
          BOUNDARIES = ::Authz::Validation::BOUNDARIES

          # Raw permissions consumed by gPATs through paths the validator cannot statically detect.
          # Today this is `Gitlab::GitAccess#check_granular_pat_permissions!`, which calls
          # `Authz::Tokens::AuthorizeGranularScopesService` directly for git protocol commands.
          GRANULAR_TOKEN_NON_API_CONSUMERS = Set[:download_code].freeze

          def initialize
            @violations = {
              schema: {},
              name: [],
              action: {},
              boundary_in_name: {},
              duplicate_name: [],
              duplicate_raw_permission: {},
              file: {},
              name_path_mismatch: {},
              resource_metadata_schema: {},
              category_metadata_schema: {},
              empty_resource_directory: [],
              empty_category_directory: [],
              granular_access_token_unused: []
            }
            @resources = []
            @categories = []
          end

          private

          attr_reader :violations, :resources, :categories

          def validate!
            defined_permissions = ::Authz::PermissionGroups::Assignable.available_definitions
            defined_permissions.each { |p| validate_permission(p) }

            validate_names
            validate_raw_permissions
            validate_resources
            validate_categories
            validate_empty_resource_directories
            validate_empty_category_directories
            validate_granular_access_token_consumers

            super
          end

          def validate_granular_access_token_consumers
            in_use = granular_access_token_raw_permissions

            ::Authz::PermissionGroups::Assignable.available_definitions.each do |assignable|
              next unless assignable.available_for?(:granular_access_token)
              next if assignable.permissions.any? { |p| in_use.include?(p) }

              violations[:granular_access_token_unused] << assignable.name
            end
          end

          def granular_access_token_raw_permissions
            (rest_granular_raw_permissions + graphql_granular_raw_permissions).to_set +
              GRANULAR_TOKEN_NON_API_CONSUMERS
          end

          def rest_granular_raw_permissions
            rest_endpoint_routes(::API::API.endpoints).flat_map do |route|
              authorization = route.settings[:authorization]
              next [] unless authorization
              next [] if authorization[:skip_granular_token_authorization]

              Array(authorization[:permissions]).map(&:to_sym)
            end
          end

          def rest_endpoint_routes(endpoints)
            endpoints.flat_map do |endpoint|
              if endpoint.respond_to?(:endpoints) && endpoint.endpoints
                rest_endpoint_routes(endpoint.endpoints)
              else
                endpoint.routes
              end
            end
          end

          def graphql_granular_raw_permissions
            graphql_granular_directives.flat_map do |directive|
              Array(directive.arguments[:permissions]).map { |p| p.to_s.downcase.to_sym }
            end
          end

          def graphql_granular_directives
            directives = []

            GitlabSchema.types.each do |type_name, type|
              next if type_name.start_with?('__')

              if type.respond_to?(:directives)
                type.directives.each do |d|
                  directives << d if d.is_a?(::Directives::Authz::GranularScope)
                end
              end

              next unless type.respond_to?(:fields)

              type.fields.each_value do |field|
                next unless field.respond_to?(:directives)

                field.directives.each do |d|
                  directives << d if d.is_a?(::Directives::Authz::GranularScope)
                end
              end
            end

            directives
          end

          def validate_permission(permission)
            validate_schema(permission)
            validate_name(permission)
            validate_action(permission)
            validate_boundary_in_name(permission)
            validate_file(permission)
            validate_name_path(permission)

            # Collect unique resources and categories for metadata validation
            return unless permission.category.present? && permission.resource.present?

            @resources << { category: permission.category, resource: permission.resource }
            @categories << permission.category
          end

          def permission_source_paths(permission_name)
            [assignable_source_path(permission_name)]
          end

          def validate_boundary_in_name(permission)
            return unless permission.resource.present?

            boundary = BOUNDARIES.find { |b| permission.resource.start_with?("#{b}_") }
            return unless boundary

            violations[:boundary_in_name][permission.name] = boundary
          end

          def validate_file(permission)
            expected_file_path_data = expected_file_path_data(permission)

            return if permission.source_file.match?(expected_file_path_data[:pattern])

            name_and_actual_path = "#{permission.name} in #{expected_file_path_data[:actual_path]}"
            violations[:file][name_and_actual_path] = expected_file_path_data[:expected]
          end

          # Ensure resource and action based on the path matches name field value
          def validate_name_path(permission)
            return unless permission.resource.present? && permission.action.present?

            name_from_path = "#{permission.action}_#{permission.resource}"
            return if name_from_path == permission.name

            violations[:name_path_mismatch][permission.name] =
              "Path must match '#{PERMISSION_DIR}/<category>/<resource>/<action>.yml' " \
                "based on <resource> and <action> values from '#{permission.name}' ('<action>_<resource>')"
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
            non_deprecated = ::Authz::PermissionGroups::Assignable.available_definitions
            all_raw_permissions = non_deprecated.flat_map(&:permissions).uniq

            duplicates = all_raw_permissions.filter_map do |raw_permission|
              assignables = non_deprecated.select { |a| a.permissions.include?(raw_permission) }
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
            # Check resource directories (inside category directories) for having only .metadata.yml
            violations[:empty_resource_directory] = find_empty_directories("#{PERMISSION_DIR}/*/*/")
          end

          def validate_empty_category_directories
            # Check category directories for having only .metadata.yml with no resource subdirectories
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
            out = format_schema_errors { |name| assignable_source_path(name) }
            out += format_error_list_with_source(:name)
            out += format_action_errors
            out += format_boundary_in_name_errors
            out += format_duplicate_name_errors
            out += format_duplicate_raw_permission_errors
            out += format_file_errors
            out += format_name_path_mismatch_errors
            out += format_schema_errors(:resource_metadata_schema) { |id| metadata_path(id) }
            out += format_schema_errors(:category_metadata_schema) { |id| metadata_path(id) }
            out += format_error_list(:empty_resource_directory)
            out += format_error_list(:empty_category_directory)
            out + format_granular_access_token_unused_errors
          end

          def format_granular_access_token_unused_errors
            return '' if violations[:granular_access_token_unused].empty?

            out = "#{error_messages[:granular_access_token_unused]}\n\n"

            violations[:granular_access_token_unused].each do |name|
              out += "  - #{name} (#{assignable_source_path(name)})\n"
            end

            "#{out}\n"
          end

          def metadata_path(identifier)
            "#{PERMISSION_DIR}/#{identifier}/.metadata.yml"
          end

          def format_boundary_in_name_errors
            return '' if violations[:boundary_in_name].empty?

            out = "#{error_messages[:boundary_in_name]}\n\n"

            violations[:boundary_in_name].each do |permission, boundary|
              source = assignable_source_path(permission)

              out += "  - #{permission}: Resource should not start with boundary '#{boundary}'. (#{source})\n"
            end

            "#{out}\n"
          end

          def format_duplicate_name_errors
            return '' if violations[:duplicate_name].empty?

            out = "#{error_messages[:duplicate_name]}\n\n"

            violations[:duplicate_name].each do |name|
              sources = assignable_source_paths_by_name(name)
              out += "  - #{name}"
              out += " (#{sources.join(', ')})" if sources.any?
              out += "\n"
            end

            "#{out}\n"
          end

          def format_duplicate_raw_permission_errors
            return '' if violations[:duplicate_raw_permission].empty?

            out = "#{error_messages[:duplicate_raw_permission]}\n\n"

            violations[:duplicate_raw_permission].keys.sort.each do |raw_permission|
              assignable_names = violations[:duplicate_raw_permission][raw_permission]
              sources = assignable_names.sort.map do |name|
                "#{name} (#{assignable_source_path(name)})"
              end
              out += "  - #{raw_permission}: found in #{sources.join(', ')}\n"
            end

            "#{out}\n"
          end

          def format_name_path_mismatch_errors
            return '' if violations[:name_path_mismatch].empty?

            out = "#{error_messages[:name_path_mismatch]}\n"

            violations[:name_path_mismatch].each do |permission, expected|
              out += "\n  - #{permission} (#{assignable_source_path(permission)})\n    #{expected}\n"
            end

            "#{out}\n"
          end

          def assignable_source_path(name)
            permission = ::Authz::PermissionGroups::Assignable.all[name.to_sym]
            relative_path(permission.source_file)
          end

          def assignable_source_paths_by_name(name)
            ::Authz::PermissionGroups::Assignable.all.values
              .select { |p| p.name == name }
              .map { |p| relative_path(p.source_file) }
          end

          def error_messages
            {
              schema: "The following permissions failed schema validation." \
                "\n#{assignable_permissions_link(anchor: 'create-the-assignable-permission-file')}",
              name: "The following assignable permissions have invalid names." \
                "\nPermission name must be in the format action_resource[_subresource]." \
                "\n#{conventions_link(anchor: 'naming-permissions')}",
              action: "The following assignable permissions contain a disallowed action." \
                "\n#{conventions_link(anchor: 'disallowed-actions')}",
              boundary_in_name: "The following assignable permissions encode a resource boundary in their name." \
                "\nThe permission name should not include the boundary (project, group, user) as a prefix." \
                "\n#{conventions_link(anchor: 'avoiding-resource-boundaries-in-permission-names')}",
              duplicate_name: "The following permissions have duplicate names." \
                "\nAssignable permissions must have unique names." \
                "\n#{assignable_permissions_link(anchor: 'important-constraints')}",
              duplicate_raw_permission: "The following raw permissions are used in multiple assignable permissions." \
                "\nEach raw permission should only belong to one assignable permission." \
                "\n#{assignable_permissions_link(anchor: 'important-constraints')}",
              file: "The following permission definitions do not exist at the expected path." \
                "\n#{assignable_permissions_link(anchor: 'understanding-the-directory-structure')}",
              name_path_mismatch: "The following permission names do not match their file path." \
                "\nThe permission name must equal '<action>_<resource>' derived from the path." \
                "\n#{conventions_link(anchor: 'naming-permissions')}",
              resource_metadata_schema:
                "The following assignable permission resource metadata file failed schema validation." \
                "\n#{assignable_permissions_link(anchor: 'when-do-you-need-metadata-files')}",
              category_metadata_schema:
                "The following assignable permission category metadata file failed schema validation." \
                "\n#{assignable_permissions_link(anchor: 'understanding-the-directory-structure')}",
              empty_resource_directory:
                "The following resource directories contain only a .metadata.yml file with no permission definitions." \
                "\nEither add permission definitions or remove the directory." \
                "\n#{assignable_permissions_link(anchor: 'understanding-the-directory-structure')}",
              empty_category_directory:
                "The following category directories contain only a .metadata.yml file with no resource " \
                "subdirectories.\nEither add resource subdirectories or remove the directory." \
                "\n#{assignable_permissions_link(anchor: 'understanding-the-directory-structure')}",
              granular_access_token_unused:
                "The following assignable permissions declare `available_for: granular_access_token` but none " \
                "of their raw permissions are referenced by any REST authorization or GraphQL granular scope " \
                "directive.\nEither remove `granular_access_token` from `available_for`, or reference one of " \
                "the raw permissions in a route/directive." \
                "\n#{assignable_permissions_link(anchor: 'available-for-consumers')}"
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
