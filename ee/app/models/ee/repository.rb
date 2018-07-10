module EE
  # Repository EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Repository` model
  module Repository
    extend ActiveSupport::Concern

    included do
      delegate :checksum, to: :raw_repository
    end

    # Transiently sets a configuration variable
    # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/1241
    def with_config(values = {})
      ::Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        values.each { |k, v| rugged.config[k] = v }
      end

      yield
    ensure
      ::Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        values.keys.each { |key| rugged.config.delete(key) }
      end
    end

    # Runs code after a repository has been synced.
    def after_sync
      expire_all_method_caches
      expire_branch_cache if exists?
      expire_content_cache
    end

    def upstream_branches
      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/1243
      ::Gitlab::GitalyClient::StorageSettings.allow_disk_access { super }
    end
  end
end
