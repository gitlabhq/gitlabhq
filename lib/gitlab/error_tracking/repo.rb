# frozen_string_literal: true

# This should be in the ErrorTracking namespace. For more details, see:
# https://gitlab.com/gitlab-org/gitlab/-/issues/323342
module Gitlab
  module ErrorTracking
    class Repo
      attr_accessor :status, :integration_id, :project_id

      def initialize(status:, integration_id:, project_id:)
        @status = status
        @integration_id = integration_id
        @project_id = project_id
      end
    end
  end
end
