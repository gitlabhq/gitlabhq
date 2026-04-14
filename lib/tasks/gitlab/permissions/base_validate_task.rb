# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      class BaseValidateTask
        attr_reader :declarative_policy_permissions

        DOCS_ROOT = 'https://docs.gitlab.com'

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

          violations[key].each_key do |identifier|
            source = block_given? ? yield(identifier) : nil
            out += "  - #{identifier}"
            out += " (#{source})" if source
            out += "\n"
            violations[key][identifier].each { |error| out += "      - #{JSONSchemer::Errors.pretty(error)}\n" }
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
            permission_files = yml_files.reject { |f| f == '.metadata.yml' }

            permission_files.empty? && yml_files.include?('.metadata.yml')
          end
        end

        def find_empty_parent_directories(glob_pattern)
          Dir.glob(glob_pattern).select do |dir|
            subdirs = Dir.glob("#{dir}*/").select { |d| File.directory?(d) }

            subdirs.empty? && File.exist?("#{dir}.metadata.yml")
          end
        end

        def relative_path(file)
          Pathname.new(file).relative_path_from(Rails.root).to_s
        end

        def implementation_guide_link(anchor: nil)
          build_doc_link('development/permissions/granular_access/rest_api_implementation_guide', anchor: anchor)
        end

        def conventions_link(anchor: nil)
          build_doc_link('development/permissions/conventions', anchor: anchor)
        end

        def permission_definitions_link(anchor: nil)
          build_doc_link('development/permissions/granular_access/permission_definitions', anchor: anchor)
        end

        def assignable_permissions_link(anchor: nil)
          build_doc_link('development/permissions/granular_access/assignable_permissions', anchor: anchor)
        end

        def build_doc_link(link, anchor: nil)
          doc_url = "#{DOCS_ROOT}/#{link}"

          doc_url = "#{doc_url}/##{anchor}" if anchor

          "Learn more: #{doc_url}"
        end
      end
    end
  end
end
