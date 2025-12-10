# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      class BaseValidateTask
        attr_reader :declarative_policy_permissions

        def initialize; end

        def run
          validate!

          print_success_message
        end

        private

        attr_reader :violations

        def validate!
          abort_if_errors_found!
        end

        def abort_if_errors_found!
          return if violations.all? { |_, v| v.empty? }

          print_errors(format_all_errors)

          abort
        end

        def print_success_message
          puts "Permission definitions are up-to-date"
        end

        def print_errors(formatted_errors)
          puts "#######################################################################\n#"
          puts formatted_errors.gsub(/^/, '#  ').gsub(/\s+$/, '')
          puts "#######################################################################"
        end

        def format_error_list(kind)
          return '' if violations[kind].empty?

          out = "#{error_messages[kind]}\n\n"

          violations[kind].each do |permission|
            out += "  - #{permission}\n"
          end

          "#{out}\n"
        end

        def format_schema_errors
          return '' if violations[:schema].empty?

          out = "#{error_messages[:schema]}\n\n"

          violations[:schema].each_key do |permission|
            out += "  - #{permission}\n"
            violations[:schema][permission].each { |error| out += "      - #{JSONSchemer::Errors.pretty(error)}\n" }
          end

          "#{out}\n"
        end

        def format_file_errors
          return '' if violations[:file].empty?

          out = "#{error_messages[:file]}\n"

          violations[:file].each do |permission, expected|
            out += "\n  - #{permission}\n    #{expected}\n"
          end

          "#{out}\n"
        end

        def validate_schema(permission)
          name = permission.name || permission.source_file
          errors = schema_validator.validate(permission.definition)
          violations[:schema][name] = errors if errors.any?
        end

        def error_messages
          raise NotImplementedError
        end

        def format_all_errors
          raise NotImplementedError
        end

        def json_schema_file
          raise NotImplementedError
        end

        def schema_validator
          @schema_validator ||= JSONSchemer.schema(json_schema_file)
        end
      end
    end
  end
end
