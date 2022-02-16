# frozen_string_literal: true

module Gitlab
  module Audit
    class CiRunnerTokenAuthor < Gitlab::Audit::NullAuthor
      # Represents a CI Runner token (registration or authentication)
      #
      # @param [AuditEvent] audit_event event representing a runner registration/un-registration operation
      def initialize(audit_event)
        if audit_event.details.include?(:runner_authentication_token)
          token = audit_event.details[:runner_authentication_token]
          name = "Authentication token: #{token}"
        elsif audit_event.details.include?(:runner_registration_token)
          token = audit_event.details[:runner_registration_token]
          name = "Registration token: #{token}"
        else
          raise ArgumentError, 'Runner token missing'
        end

        super(id: -1, name: name)

        @entity_type = audit_event.entity_type
        @entity_path = audit_event.entity_path
      end

      def full_path
        url_helpers = ::Gitlab::Routing.url_helpers

        case @entity_type
        when 'Group'
          url_helpers.group_settings_ci_cd_path(@entity_path, anchor: 'js-runners-settings')
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
