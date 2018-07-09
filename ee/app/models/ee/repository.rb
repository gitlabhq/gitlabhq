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
    def with_config(values = {})
      raw_repository.set_config(values)

      yield
    ensure
      raw_repository.delete_config(*values.keys)
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
