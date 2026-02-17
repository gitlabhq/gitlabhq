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

        def format_schema_errors(key = :schema)
          return '' if violations[key].empty?

          out = "#{error_messages[key]}\n\n"

          violations[key].each_key do |permission|
            out += "  - #{permission}\n"
            violations[key][permission].each { |error| out += "      - #{JSONSchemer::Errors.pretty(error)}\n" }
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

        def find_empty_directories(glob_pattern)
          Dir.glob(glob_pattern).select do |dir|
            yml_files = Dir.glob("#{dir}*.yml").map { |f| File.basename(f) }
            permission_files = yml_files.reject { |f| f == '_metadata.yml' }

            permission_files.empty? && yml_files.include?('_metadata.yml')
          end
        end

        def find_empty_parent_directories(glob_pattern)
          Dir.glob(glob_pattern).select do |dir|
            subdirs = Dir.glob("#{dir}*/").select { |d| File.directory?(d) }

            subdirs.empty? && File.exist?("#{dir}_metadata.yml")
          end
        end
      end
    end
  end
end
