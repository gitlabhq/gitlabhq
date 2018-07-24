module EE
  # Repository EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Repository` model
  module Repository
    extend ActiveSupport::Concern

    MIRROR_REMOTE = "upstream".freeze

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

    def fetch_upstream(url)
      add_remote(MIRROR_REMOTE, url)
      fetch_remote(MIRROR_REMOTE, ssh_auth: project&.import_data)
    end

    def upstream_branches
      @upstream_branches ||= remote_branches(MIRROR_REMOTE)
    end

    def diverged_from_upstream?(branch_name)
      branch_commit = commit("refs/heads/#{branch_name}")
      upstream_commit = commit("refs/remotes/#{MIRROR_REMOTE}/#{branch_name}")

      if upstream_commit
        !raw_repository.ancestor?(branch_commit.id, upstream_commit.id)
      else
        false
      end
    end

    def upstream_has_diverged?(branch_name, remote_ref)
      branch_commit = commit("refs/heads/#{branch_name}")
      upstream_commit = commit("refs/remotes/#{remote_ref}/#{branch_name}")

      if upstream_commit
        !raw_repository.ancestor?(upstream_commit.id, branch_commit.id)
      else
        false
      end
    end

    def up_to_date_with_upstream?(branch_name)
      branch_commit = commit("refs/heads/#{branch_name}")
      upstream_commit = commit("refs/remotes/#{MIRROR_REMOTE}/#{branch_name}")

      if upstream_commit
        ancestor?(branch_commit.id, upstream_commit.id)
      else
        false
      end
    end
  end
end
