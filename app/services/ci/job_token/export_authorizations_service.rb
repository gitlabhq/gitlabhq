# frozen_string_literal: true

# This class exports CI job token authorizations to a given project.
module Ci
  module JobToken
    class ExportAuthorizationsService
      include Gitlab::Allowable

      def initialize(current_user:, accessed_project:)
        @current_user = current_user
        @accessed_project = accessed_project
      end

      def execute
        unless can?(current_user, :admin_project, accessed_project)
          return ServiceResponse.error(message: _('Access denied'), reason: :forbidden)
        end

        csv_data = CsvBuilder.new(authorizations, header_to_value_hash).render

        ServiceResponse.success(payload: { data: csv_data, filename: csv_filename })
      end

      private

      attr_reader :accessed_project, :current_user

      def authorizations
        Ci::JobToken::Authorization.for_project(accessed_project).preload_origin_project
      end

      def header_to_value_hash
        {
          'Origin Project Path' => ->(auth) { auth.origin_project.full_path },
          'Last Authorized At (UTC)' => ->(auth) { auth.last_authorized_at.utc.iso8601 }
        }
      end

      def csv_filename
        "job-token-authorizations-#{accessed_project.id}-#{Time.current.to_fs(:number)}.csv"
      end
    end
  end
end
