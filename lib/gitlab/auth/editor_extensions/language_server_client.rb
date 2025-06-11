# frozen_string_literal: true

module Gitlab
  module Auth
    module EditorExtensions
      class LanguageServerClient
        USER_AGENT_PATTERN = /gitlab-language-server|code-completions-language-server-experiment/
        VERSION_PATTERN = ::Gitlab::Regex.semver_regex

        def initialize(client_version:, user_agent:)
          @client_version = client_version
          @user_agent = user_agent
        end

        def lsp_client?
          # Either condition is sufficient to identify an LSP client:
          # - client_version matching semantic versioning pattern, or
          # - user_agent containing known LSP client identifiers
          client_version&.match(VERSION_PATTERN) || user_agent&.match(USER_AGENT_PATTERN)
        end

        def version
          return Gem::Version.new(client_version) if client_version&.match(VERSION_PATTERN)

          # For older clients it is likely LSP version information is absent.
          Gem::Version.new('0.1.0')
        end

        private

        attr_reader :client_version, :user_agent
      end
    end
  end
end
