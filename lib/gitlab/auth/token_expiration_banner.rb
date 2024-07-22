# frozen_string_literal: true

module Gitlab
  module Auth
    module TokenExpirationBanner
      module_function

      # rubocop:disable Gitlab/ModuleWithInstanceVariables, CodeReuse/ActiveRecord -- simple query and should be memoized per app boot
      def show_token_expiration_banner?
        return @show_token_expiration_banner unless @show_token_expiration_banner.nil?

        if %w[1 yes true].include?(ENV.fetch('GITLAB_DISABLE_TOKEN_EXPIRATION_BANNER', false))
          @show_token_expiration_banner = false
          return @show_token_expiration_banner
        end

        unless Gitlab.version_info >= Gitlab::VersionInfo.new(16, 0) &&
            Gitlab.version_info < Gitlab::VersionInfo.new(17, 1)
          @show_token_expiration_banner = false
          return @show_token_expiration_banner
        end

        @show_token_expiration_banner = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
          job_class_name: 'CleanupPersonalAccessTokensWithNilExpiresAt'
        ).exists?
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables, CodeReuse/ActiveRecord
    end
  end
end
