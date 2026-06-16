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
          sync_todo if self.class.const_defined?(:TODO_FILE, false)

          print_success_message
        end

        def load_todo_entries
          @todo_entries ||= begin
            todo_file = self.class::TODO_FILE
            if todo_file.exist?
              todo_file.readlines.each_with_object(Set.new) do |line, set|
                stripped = line.strip
                set << stripped unless stripped.empty? || stripped.start_with?('#')
              end
            else
              Set.new
            end
          end
        end

        def sync_todo
          stale = load_todo_entries - current_todo_entries
          return if stale.empty?

          update_todo
          print_errors(format_stale_todo_entries(stale))
          abort
        end

        def update_todo
          entries = current_todo_entries
          header = extract_todo_header
          self.class::TODO_FILE.write("#{header}#{entries.sort.join("\n")}\n")
          puts "The #{todo_file_label} todo file updated (#{entries.size} entries)."
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
          puts "Permission definitions are valid"
        end

        def print_errors(formatted_errors)
          puts "#######################################################################\n#"
          puts formatted_errors.gsub(/^/, '#  ').gsub(/\s+$/, '')
          puts "#######################################################################"
        end

        def format_stale_todo_entries(stale)
          out = "The #{todo_file_label} todo file had stale entries and has been updated.\n"
          out += "Please commit #{relative_path(self.class::TODO_FILE)}.\n\n"
          stale.sort.each { |entry| out += "  - #{entry}\n" }
          "#{out}\n"
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

        def validate_name(permission)
          return if self.class::PERMISSION_NAME_REGEX.match?(permission.name)

          violations[:name] << permission.name
        end

        def validate_action(permission)
          return if permission.try(:deprecated?)
          return unless permission.action.present?
          return unless self.class::DISALLOWED_ACTIONS.key?(permission.action.to_sym)

          violations[:action][permission.name] = permission.action.to_sym
        end

        def format_error_list_with_source(kind)
          return '' if violations[kind].empty?

          out = "#{error_messages[kind]}\n\n"

          violations[kind].each do |permission|
            sources = permission_source_paths(permission)
            out += "  - #{permission} (#{sources.join(', ')})\n"
          end

          "#{out}\n"
        end

        def format_action_errors
          return '' if violations[:action].empty?

          out = "#{error_messages[:action]}\n\n"

          violations[:action].each do |permission, action|
            preferred = self.class::DISALLOWED_ACTIONS[action]
            source = permission_source_paths(permission).first

            out += "  - #{permission}: Prefer #{preferred} over #{action}. (#{source})\n"
          end

          "#{out}\n"
        end

        def current_todo_entries
          raise NotImplementedError
        end

        def todo_file_label
          raise NotImplementedError
        end

        def extract_todo_header
          return '' unless self.class::TODO_FILE.exist?

          self.class::TODO_FILE.readlines
            .take_while { |line| line.start_with?('#') || line.chomp.empty? }
            .join
        end

        def permission_source_paths(_permission_name)
          raise NotImplementedError
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

        def graphql_implementation_guide_link(anchor: nil)
          build_doc_link('development/permissions/granular_access/graphql_implementation_guide', anchor: anchor)
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
