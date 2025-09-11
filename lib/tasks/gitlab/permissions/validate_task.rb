# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      class ValidateTask
        PERMISSION_TODO_FILE = 'config/authz/permissions/definitions_todo.txt'
        JSON_SCHEMA_FILE = 'config/authz/permissions/type_schema.json'

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
          docs: "The following permissions are missing a documentation file." \
            "\nRun bundle exec rails generate authz:permission <NAME> to generate documentation files.",
          excluded: "The following permissions have a documentation file." \
            "\nRemove them from config/authz/permissions/definitions_todo.txt.",
          schema: "The following permissions failed schema validation.",
          action: "The following permissions contain a disallowed action."
        }.freeze

        def initialize
          @violations = {
            docs: [],
            excluded: [],
            schema: {},
            action: {}
          }
          @defined_permissions = []
        end

        def run
          declarative_policy_permissions.each { |permission| validate_permission(permission) }

          abort_if_errors_found!

          puts "Permissions documentation is up-to-date"
        end

        private

        attr_reader :defined_permissions, :violations

        def declarative_policy_permissions
          require_policy_files

          permissions = []

          DeclarativePolicy::Base.descendants.each do |policy_class|
            permissions += policy_class.ability_map.map.keys
          end

          permissions.sort.uniq
        end

        def abort_if_errors_found!
          return if violations.all? { |_, v| v.empty? }

          print_errors

          abort
        end

        def print_errors
          out = format_doc_errors
          out += format_schema_errors
          out += format_action_errors

          puts "#######################################################################\n#"
          puts out.gsub(/^/, '#  ').gsub(/\s+$/, '')
          puts "#######################################################################"
        end

        def format_doc_errors
          out = ''

          %i[docs excluded].each do |kind|
            next if violations[kind].empty?

            out += "#{ERROR_MESSAGES[kind]}\n\n"
            violations[kind].each { |v| out += "  - #{v}\n" }
            out += "\n"
          end

          out
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

        def require_policy_files
          Dir["./app/policies/**/*.rb"].each { |file| require file }
          Dir["./ee/app/policies/**/*.rb"].each { |file| require file }
        end

        def validate_permission(permission_name)
          excluded = exclusion_list.include?(permission_name)
          permission = Authz::Permission.get(permission_name)

          if permission.present?
            violations[:excluded] << permission_name if excluded

            errors = schema_validator.validate(permission.definition)
            violations[:schema][permission_name] = errors if errors.any?

            validate_action(permission_name)
          else
            violations[:docs] << permission_name unless excluded
          end
        end

        def validate_action(permission_name)
          action = permission_name.to_s.split('_').first.to_sym

          preferred_action = DISALLOWED_ACTIONS[action]
          return unless preferred_action

          violations[:action][permission_name] = action
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
