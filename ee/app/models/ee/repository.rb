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

    def squash(user, merge_request)
      raw.squash(user, merge_request.id, branch: merge_request.target_branch,
                                         start_sha: merge_request.diff_start_sha,
                                         end_sha: merge_request.diff_head_sha,
                                         author: merge_request.author,
                                         message: merge_request.title)
    end
  end
end
