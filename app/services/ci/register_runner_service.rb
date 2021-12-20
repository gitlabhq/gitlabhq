# frozen_string_literal: true

module Ci
  class RegisterRunnerService
    def execute(registration_token, attributes)
      runner_type_attrs = check_token_and_extract_attrs(registration_token)

      return unless runner_type_attrs

      ::Ci::Runner.create(attributes.merge(runner_type_attrs))
    end

    private

    def check_token_and_extract_attrs(registration_token)
      if runner_registration_token_valid?(registration_token)
        # Create shared runner. Requires admin access
        { runner_type: :instance_type }
      elsif runner_registrar_valid?('project') && project = ::Project.find_by_runners_token(registration_token)
        # Create a specific runner for the project
        { runner_type: :project_type, projects: [project] }
      elsif runner_registrar_valid?('group') && group = ::Group.find_by_runners_token(registration_token)
        # Create a specific runner for the group
        { runner_type: :group_type, groups: [group] }
      end
    end

    def runner_registration_token_valid?(registration_token)
      ActiveSupport::SecurityUtils.secure_compare(registration_token, Gitlab::CurrentSettings.runners_registration_token)
    end

    def runner_registrar_valid?(type)
      Feature.disabled?(:runner_registration_control) || Gitlab::CurrentSettings.valid_runner_registrars.include?(type)
    end
  end
end
