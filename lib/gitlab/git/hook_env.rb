# frozen_string_literal: true

# Gitaly note: JV: no RPC's here.

module Gitlab
  module Git
    # Ephemeral (per request) storage for environment variables that some
    # Git commands need during internal API calls made from the Git
    # pre-receive push hook.
    #
    # See
    # https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/object_quarantine.md#gitlab-and-git-object-quarantine
    # for more information.
    #
    # This class is thread-safe via RequestStore.
    class HookEnv
      ALLOWLISTED_VARIABLES = %w[
        GIT_OBJECT_DIRECTORY_RELATIVE
        GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE
        GIT_MVCC_MANIFEST
      ].freeze

      # set stores the quarantining variables into request store.
      #
      # relative_path is sent from Gitaly to Rails when invoking internal API. In production it points to the
      # transaction's snapshot repository. Tests should pass the original relative path of the repository as
      # Gitaly is stubbed out from the invokation loop and doesn't create a transaction snapshot.
      def self.set(gl_repository, relative_path, env)
        return unless Gitlab::SafeRequestStore.active?

        raise "missing gl_repository" if gl_repository.blank?

        allowed_env = allowlist_git_env(env)

        Gitlab::SafeRequestStore[:gitlab_git_env] ||= {}
        Gitlab::SafeRequestStore[:gitlab_git_env][gl_repository] = allowed_env
        Gitlab::SafeRequestStore[:gitlab_git_relative_path] = relative_path

        # Gitaly's pre-receive hook exports the in-flight MVCC manifest sha via
        # GIT_MVCC_MANIFEST (allowlisted above); pin the request to it so
        # outbound Gitaly calls resolve OIDs against the just-uploaded state.
        pin_mvcc_manifest(allowed_env['GIT_MVCC_MANIFEST'])
      end

      # pin_mvcc_manifest validates the in-flight MVCC manifest sha forwarded by
      # Gitaly and, when well-formed, pins the current Rails request to it via
      # Gitlab::ApplicationContext. Pushing it onto the context makes it visible
      # to synchronous outbound Gitaly calls AND to Sidekiq jobs enqueued from
      # the request (the Sidekiq middleware captures ApplicationContext at
      # enqueue and restores it on perform); the Gitaly client forwards it as
      # x-gitaly-mvcc-manifest gRPC metadata.
      #
      # A malformed value is dropped rather than injected into gRPC metadata. We
      # log the drop because a missing pin silently degrades reads to the
      # durable base -- the exact failure this mechanism exists to prevent.
      def self.pin_mvcc_manifest(manifest)
        return if manifest.blank?

        unless Gitlab::Git::COMMIT_ID.match?(manifest)
          Gitlab::AppJsonLogger.warn(message: 'Ignoring malformed MVCC manifest pin')
          return
        end

        Gitlab::ApplicationContext.push(mvcc_manifest: manifest)
      end

      # mvcc_manifest returns the in-flight MVCC manifest sha that the
      # originating Gitaly's pre-receive hook uploaded to durable
      # storage and pinned the current Rails request to, or nil.
      # Outbound Gitaly gRPC calls forward this as x-gitaly-mvcc-manifest
      # metadata so the callback handler--which may land on any
      # Gitaly replica--resolves OIDs against the just-uploaded state
      # rather than the durable base.
      def self.mvcc_manifest
        Gitlab::ApplicationContext.current_context_attribute(:mvcc_manifest)
      end

      # get_relative_path returns the relative path of the repository this hook call is triggered for.
      # This is the repository's relative path in the transaction's snapshot and is passed back to Gitaly
      # in quarantined calls.
      def self.get_relative_path
        return unless Gitlab::SafeRequestStore.active?

        Gitlab::SafeRequestStore.fetch(:gitlab_git_relative_path)
      end

      def self.all(gl_repository)
        return {} unless Gitlab::SafeRequestStore.active?

        h = Gitlab::SafeRequestStore.fetch(:gitlab_git_env) { {} }
        h.fetch(gl_repository, {})
      end

      def self.to_env_hash(gl_repository)
        env = {}

        all(gl_repository).compact.each do |key, value|
          value = value.join(File::PATH_SEPARATOR) if value.is_a?(Array)
          env[key.to_s] = value
        end

        env
      end

      def self.allowlist_git_env(env)
        env.select { |key, _| ALLOWLISTED_VARIABLES.include?(key.to_s) }.with_indifferent_access
      end
    end
  end
end
