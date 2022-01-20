# frozen_string_literal: true

module Gitlab
  module Audit
    class RunnerRegistrationTokenAuthor < Gitlab::Audit::NullAuthor
      def initialize(token:, entity_type:, entity_path:)
        super(id: -1, name: "Registration token: #{token}")

        @entity_type = entity_type
        @entity_path = entity_path
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
