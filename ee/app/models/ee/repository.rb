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
      values.each { |k, v| rugged.config[k] = v }

      yield
    ensure
      values.keys.each { |key| rugged.config.delete(key) }
    end

    # Runs code after a repository has been synced.
    def after_sync
      expire_all_method_caches
      expire_branch_cache if exists?
      expire_content_cache
    end
  end
end
