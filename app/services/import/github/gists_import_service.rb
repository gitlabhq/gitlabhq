# frozen_string_literal: true

module Import
  module Github
    class GistsImportService < ::BaseService
      def initialize(user, params)
        @current_user = user
        @params = params
      end

      def execute
        return error('Import already in progress', 422) if import_status.started?

        start_import
        success
      end

      private

      def import_status
        @import_status ||= Gitlab::GithubGistsImport::Status.new(current_user.id)
      end

      def encrypted_token
        Gitlab::CryptoHelper.aes256_gcm_encrypt(params[:github_access_token])
      end

      def start_import
        Gitlab::GithubGistsImport::StartImportWorker.perform_async(current_user.id, encrypted_token)
        import_status.start!
      end
    end
  end
end
