# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill `admin_mode` scope for a range of personal access tokens
    class BackfillAdminModeScopeForPersonalAccessTokens < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      scope_to ->(relation) do
        relation.joins('INNER JOIN users ON personal_access_tokens.user_id = users.id')
                .where(users: { admin: true })
                .where(revoked: [false, nil])
                .where.not('expires_at IS NOT NULL AND expires_at <= ?', Time.current)
      end

      operation_name :update_all
      feature_category :authentication_and_authorization

      ADMIN_MODE_SCOPE = ['admin_mode'].freeze

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |token|
            token.update!(scopes: (YAML.safe_load(token.scopes) + ADMIN_MODE_SCOPE).uniq.to_yaml)
          end
        end
      end
    end
  end
end
