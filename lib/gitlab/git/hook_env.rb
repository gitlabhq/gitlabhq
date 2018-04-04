# Gitaly note: JV: no RPC's here.

module Gitlab
  module Git
    # Ephemeral (per request) storage for environment variables that some Git
    # commands need during internal API calls made from Git push hooks.
    #
    # For example, in pre-receive hooks, new objects are put in a temporary
    # $GIT_OBJECT_DIRECTORY. Without it set, the new objects cannot be retrieved
    # (this would break push rules for instance).
    #
    # This class is thread-safe via RequestStore.
    class HookEnv
      WHITELISTED_VARIABLES = %w[
        GIT_OBJECT_DIRECTORY_RELATIVE
        GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE
      ].freeze

      def self.set(gl_repository, env)
        return unless RequestStore.active?

        raise "missing gl_repository" if gl_repository.blank?

        RequestStore.store[:gitlab_git_env] ||= {}
        RequestStore.store[:gitlab_git_env][gl_repository] = whitelist_git_env(env)
      end

      def self.all(gl_repository)
        return {} unless RequestStore.active?

        h = RequestStore.fetch(:gitlab_git_env) { {} }
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

      def self.whitelist_git_env(env)
        env.select { |key, _| WHITELISTED_VARIABLES.include?(key.to_s) }.with_indifferent_access
      end
    end
  end
end
