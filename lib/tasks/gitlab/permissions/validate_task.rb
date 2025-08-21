# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      class ValidateTask
        PERMISSION_TODO_FILE = 'config/authz/permissions/definitions_todo.txt'
        VIOLATION_MSG = "The following permissions are missing a documentation file\n"
        EXCLUSION_MSG = <<~MSG
          The following permissions have an entry in config/authz/permissions/definitions_todo.txt but are defined.
          Remove any defined permissions from config/authz/permissions/definitions_todo.txt.
        MSG

        def initialize
          @violations = []
          @defined_permissions = []
        end

        def run
          require_policy_files

          DeclarativePolicy::Base.descendants.each do |policy_class|
            policy_class.ability_map.map.each_key { |permission| validate_permission(permission) }
          end

          abort_if_errors_found!

          puts "Permissions documentation is up-to-date"
        end

        private

        attr_reader :defined_permissions, :violations

        def abort_if_errors_found!
          return if violations.empty? && defined_permissions.empty?

          puts "#######################################################################\n#"
          print_errors(VIOLATION_MSG, violations) unless violations.empty?
          print_errors(EXCLUSION_MSG, defined_permissions) unless defined_permissions.empty?
          puts "#######################################################################"

          abort
        end

        def print_errors(msg, list)
          out = "#{msg}\n"
          list.sort.uniq.each { |v| out += "  - #{v}\n" }
          out += "\n"

          puts out.gsub(/^/, '#  ').gsub(/\s+$/, '')
        end

        def require_policy_files
          Dir["./app/policies/**/*.rb"].each { |file| require file }
          Dir["./ee/app/policies/**/*.rb"].each { |file| require file }
        end

        def validate_permission(permission)
          excluded = exclusion_list.include?(permission)
          defined = Authz::Permission.get(permission).present?

          defined_permissions << permission if excluded && defined
          violations << permission unless excluded || defined
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
      end
    end
  end
end
