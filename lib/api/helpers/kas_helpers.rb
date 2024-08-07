# frozen_string_literal: true

module API
  module Helpers
    module KasHelpers
      def authenticate_gitlab_kas_request!
        render_api_error!('KAS JWT authentication invalid', 401) unless Gitlab::Kas.verify_api_request(headers)
      end

      def gitaly_info(project)
        Gitlab::GitalyClient.connection_data(project.repository_storage)
      end

      def gitaly_repository(project)
        project.repository.gitaly_repository.to_h
      end
    end
  end
end
