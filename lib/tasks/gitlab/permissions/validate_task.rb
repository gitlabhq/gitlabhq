# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      class ValidateTask < ::Tasks::Gitlab::Permissions::BaseValidateTask
        PERMISSION_DIR = ::Authz::Permission::BASE_PATH
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

        private

        attr_reader :violations

        def validate!
          declarative_policy_permissions.each { |permission| validate_permission(permission) }
          validate_unknown_permissions

          super
        end

        def load_declarative_policy_permissions
          require_policy_files

          permissions = []

          DeclarativePolicy::Base.descendants.each do |policy_class|
            permissions += policy_class.ability_map.map.keys
          end

          permissions.sort.uniq
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

        def validate_action(permission)
          return unless DISALLOWED_ACTIONS.has_key?(permission.action.to_sym)

          violations[:action][permission.name] = permission.action.to_sym
        end

        def validate_name(permission)
          return if PERMISSION_NAME_REGEX.match?(permission.name)

          violations[:name] << permission.name
        end

        def validate_file(permission)
          source_file = permission.source_file
          actual_path = source_file[source_file.index(PERMISSION_DIR)..]
          name = "#{permission.name} in #{actual_path}"

          # ensure file is under a resource directory and has a name
          unless permission.resource.present? && permission.action.present?
            expected_action = permission.action.presence || '<action>'
            expected_resource = permission.resource.presence || '<resource>'
            expected_path = "#{PERMISSION_DIR}/#{expected_resource}/#{expected_action}.yml"
            violations[:file][name] = "Expected path: #{expected_path}"
            return
          end

          # ensure there are no extra directories between PERMISSION_DIR and <resource>/<action>.yml
          expected_path = "#{PERMISSION_DIR}/#{permission.resource}/#{permission.action}.yml"
          unless expected_path == actual_path
            violations[:file][name] = "Expected path: #{expected_path}"
            return
          end

          # ensure resource and action based on the path matches name field value
          name_from_path = "#{permission.action}_#{permission.resource}"
          return if name_from_path == permission.name

          violations[:file][name] =
            "Path must match '#{PERMISSION_DIR}/<resource>/<action>.yml' based on <resource> and <action> values " \
              "from '#{permission.name}' ('<action>_<resource>')"
        end

        def validate_unknown_permissions
          defined_permissions = ::Authz::Permission.all.keys.map(&:to_sym)
          violations[:unknown_permission] = defined_permissions - declarative_policy_permissions
        end

        def format_all_errors
          out = format_error_list(:definition)
          out += format_error_list(:excluded)
          out += format_schema_errors
          out += format_error_list(:name)
          out += format_action_errors
          out += format_file_errors
          out + format_error_list(:unknown_permission)
        end

        def format_action_errors
          return '' if violations[:action].empty?

          out = "#{error_messages[:action]}\n\n"

          violations[:action].each_key do |permission|
            action = violations[:action][permission]
            preferred = DISALLOWED_ACTIONS[action]

            out += "  - #{permission}: Prefer #{preferred} over #{action}.\n"
          end

          "#{out}\n"
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

        def error_messages
          {
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
              "declarative policy.\nRemove the definition files for the unknown permissions."
          }
        end

        def json_schema_file
          Rails.root.join("#{PERMISSION_DIR}/type_schema.json")
        end
      end
    end
  end
end
