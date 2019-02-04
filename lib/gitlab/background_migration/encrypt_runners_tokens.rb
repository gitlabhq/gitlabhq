# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # EncryptColumn migrates data from an unencrypted column - `foo`, say - to
    # an encrypted column - `encrypted_foo`, say.
    #
    # We only create a subclass here because we want to isolate this migration
    # (migrating unencrypted runner registration tokens to encrypted columns)
    # from other `EncryptColumns` migration. This class name is going to be
    # serialized and stored in Redis and later picked by Sidekiq, so we need to
    # create a separate class name in order to isolate these migration tasks.
    #
    # We can solve this differently, see tech debt issue:
    #
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/54328
    #
    class EncryptRunnersTokens < EncryptColumns
      def perform(model, from, to)
        resource = "::Gitlab::BackgroundMigration::Models::EncryptColumns::#{model.to_s.capitalize}"
        model = resource.constantize
        attributes = model.encrypted_attributes.keys

        super(model, attributes, from, to)
      end

      def clear_migrated_values?
        false
      end
    end
  end
end
