# frozen_string_literal: true

module Gitlab
  module Audit
    class CiRunnerTokenAuthor < Gitlab::Audit::NullAuthor
      attr_reader :entity_type, :entity_path

      # Represents a CI Runner token (registration or authentication)
      #
      # @param ["gitlab_instance", "Group", "Project"] entity_type type of the scope that the token applies to
      # @param [String] entity_path full path to the scope that the token applies to
      # @param [String] runner_authentication_token authentication token used in a runner registration/un-registration
      #   operation
      # @param [String] runner_registration_token authentication token used in a runner registration operation
      def initialize(entity_type:, entity_path:, runner_authentication_token: nil, runner_registration_token: nil)
        name =
          if runner_authentication_token.present?
            "Authentication token: #{runner_authentication_token}"
          elsif runner_registration_token.present?
            "Registration token: #{runner_registration_token}"
          else
            "Token not available"
          end

        super(id: -1, name: name)

        @entity_type = entity_type
        @entity_path = entity_path
      end

      def full_path
        url_helpers = ::Gitlab::Routing.url_helpers

        case @entity_type
        when 'Group'
          url_helpers.group_runners_path(@entity_path)
        when 'Project'
          project = Project.find_by_full_path(@entity_path)
          url_helpers.project_settings_ci_cd_path(project, anchor: 'js-runners-settings') if project
        else
          url_helpers.admin_runners_path
        end
      end
    end
  end
end
