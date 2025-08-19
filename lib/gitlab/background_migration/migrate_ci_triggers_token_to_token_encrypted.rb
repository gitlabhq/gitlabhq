# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateCiTriggersTokenToTokenEncrypted < BatchedMigrationJob
      feature_category :continuous_integration
      operation_name :update
      class CiTrigger < ::Ci::ApplicationRecord
        include TokenAuthenticatable

        TRIGGER_TOKEN_PREFIX = 'glptt-'

        add_authentication_token_field :token, encrypted: :migrating, format_with_prefix: :compute_token_prefix
        self.table_name = 'ci_triggers'

        def token=(new_token)
          set_token(new_token)
        end

        def compute_token_prefix
          TRIGGER_TOKEN_PREFIX
        end
      end

      def perform
        each_sub_batch(
          batching_scope: ->(relation) {
            relation.where(token_encrypted: nil)
          }) do |sub_batch|
          sub_batch.each do |trigger|
            Gitlab::BackgroundMigration::MigrateCiTriggersTokenToTokenEncrypted::CiTrigger
            .find(trigger.id)
            .update!(token: trigger.token)
          end
        end
      end
    end
  end
end
