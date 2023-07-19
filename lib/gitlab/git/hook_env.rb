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
      ].freeze

      def self.set(gl_repository, env)
        return unless Gitlab::SafeRequestStore.active?

        raise "missing gl_repository" if gl_repository.blank?

        Gitlab::SafeRequestStore[:gitlab_git_env] ||= {}
        Gitlab::SafeRequestStore[:gitlab_git_env][gl_repository] = allowlist_git_env(env)
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
