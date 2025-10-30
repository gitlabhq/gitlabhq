# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      class ValidateTask
        PERMISSION_DIR = 'config/authz/permissions'
        PERMISSION_TODO_FILE = "#{PERMISSION_DIR}/definitions_todo.txt".freeze
        JSON_SCHEMA_FILE = 'config/authz/permissions/type_schema.json'
        PERMISSION_NAME_REGEX = /\A[a-z]+_[a-z_]+[a-z]\z/

        DISALLOWED_ACTIONS = {
          admin: 'a granular action',
          change: 'update',
          destroy: 'delete',
          edit: 'update',
          list: 'read',
          manage: 'a granular action',
          modify: 'update',
          set: 'update',
          view: 'read'
        }.freeze

        ERROR_MESSAGES = {
          definition: "The following permissions are missing a definition file." \
            "\nRun bundle exec rails generate authz:permission <NAME> to generate definition files.",
          excluded: "The following permissions have a definition file." \
            "\nRemove them from config/authz/permissions/definitions_todo.txt.",
          schema: "The following permissions failed schema validation.",
          action: "The following permissions contain a disallowed action.",
          name: "The following permissions have invalid names." \
            "\nPermission name must be in the format action_resource[_subresource].",
          file: "The following permission definitions do not exist at the expected path.",
          unknown_permission: "The following permissions have a definition file but are not found in " \
            "declarative policy.\nRemove the definition files for the unkonwn permissions."
        }.freeze

        attr_reader :declarative_policy_permissions

        def initialize
          @violations = {
            definition: [],
            excluded: [],
            schema: {},
            action: {},
            name: [],
            file: {},
            unknown_permission: []
          }
          @declarative_policy_permissions = load_declarative_policy_permissions
        end

        def run
          validate!

          puts "Permission definitions are up-to-date"
        end

        private

        attr_reader :violations

        def load_declarative_policy_permissions
          require_policy_files

          permissions = []

          DeclarativePolicy::Base.descendants.each do |policy_class|
            permissions += policy_class.ability_map.map.keys
          end

          permissions.sort.uniq
        end

        def validate!
          declarative_policy_permissions.each { |permission| validate_permission(permission) }
          validate_unknown_permissions

          abort_if_errors_found!
        end

        def abort_if_errors_found!
          return if violations.all? { |_, v| v.empty? }

          print_errors

          abort
        end

        def print_errors
          out = format_error_list(:definition)
          out += format_error_list(:excluded)
          out += format_schema_errors
          out += format_error_list(:name)
          out += format_action_errors
          out += format_file_errors
          out += format_error_list(:unknown_permission)

          puts "#######################################################################\n#"
          puts out.gsub(/^/, '#  ').gsub(/\s+$/, '')
          puts "#######################################################################"
        end

        def format_error_list(kind)
          return '' if violations[kind].empty?

          out = "#{ERROR_MESSAGES[kind]}\n\n"

          violations[kind].each do |permission|
            out += "  - #{permission}\n"
          end

          "#{out}\n"
        end

        def format_schema_errors
          return '' if violations[:schema].empty?

          out = "#{ERROR_MESSAGES[:schema]}\n\n"

          violations[:schema].each_key do |permission|
            out += "  - #{permission}\n"
            violations[:schema][permission].each { |error| out += "      - #{JSONSchemer::Errors.pretty(error)}\n" }
          end

          "#{out}\n"
        end

        def format_action_errors
          return '' if violations[:action].empty?

          out = "#{ERROR_MESSAGES[:action]}\n\n"

          violations[:action].each_key do |permission|
            action = violations[:action][permission]
            preferred = DISALLOWED_ACTIONS[action]

            out += "  - #{permission}: Prefer #{preferred} over #{action}.\n"
          end

          "#{out}\n"
        end

        def format_file_errors
          return '' if violations[:file].empty?

          out = "#{ERROR_MESSAGES[:file]}\n"

          violations[:file].each do |permission, expected_path|
            out += "\n  - Name: #{permission}\n    Expected Path: #{expected_path}\n"
          end

          "#{out}\n"
        end

        def require_policy_files
          Dir["./app/policies/**/*.rb"].each { |file| require file }
          Dir["./ee/app/policies/**/*.rb"].each { |file| require file }
        end

        def validate_permission(permission_name)
          excluded = exclusion_list.include?(permission_name)
          permission = Authz::Permission.get(permission_name)

          unless permission.present?
            violations[:definition] << permission_name unless excluded
            return
          end

          violations[:excluded] << permission_name if excluded
          validate_schema(permission)
          validate_name(permission)
          validate_action(permission)
          validate_file(permission)
        end

        def validate_schema(permission)
          errors = schema_validator.validate(permission.definition)
          violations[:schema][permission.name] = errors if errors.any?
        end

        def validate_action(permission)
          return unless DISALLOWED_ACTIONS.has_key?(permission.action.to_sym)

          violations[:action][permission.name] = permission.action.to_sym
        end

        def validate_name(permission)
          return if PERMISSION_NAME_REGEX.match?(permission.name)

          violations[:name] << permission.name
        end

        def validate_file(permission)
          # No need to check the file path with an invalid name
          return unless permission.action && permission.resource

          expected_file = "#{PERMISSION_DIR}/#{permission.resource}/#{permission.action}.yml"
          return if permission.source_file.ends_with?(expected_file)

          violations[:file][permission.name] = expected_file
        end

        def validate_unknown_permissions
          defined_permissions = ::Authz::Permission.all.keys.map(&:to_sym)
          violations[:unknown_permission] = defined_permissions - declarative_policy_permissions
        end

        def exclusion_list
          @excludes ||= if File.exist?(exclusion_file)
                          File.read(exclusion_file).split("\n").reject(&:empty?).map { |p| p.strip.to_sym }
                        else
                          []
                        end
        end

        def exclusion_file
          Rails.root.join(PERMISSION_TODO_FILE)
        end

        def schema_validator
          @schema_validator ||= JSONSchemer.schema(Rails.root.join(JSON_SCHEMA_FILE))
        end
      end
    end
  end
end
