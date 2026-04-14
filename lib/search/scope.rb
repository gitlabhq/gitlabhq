# frozen_string_literal: true

module Search
  module Scope
    ALWAYS_ALLOWED_SCOPES = %w[projects milestones].freeze
    GLOBAL_SCOPES = %w[issues merge_requests snippet_titles users].freeze
    PROJECT_SCOPES = ALWAYS_ALLOWED_SCOPES + GLOBAL_SCOPES + %w[blobs wiki_blobs commits notes].freeze

    SCOPE_TO_SETTING = {
      blobs: :code,
      wiki_blobs: :wiki,
      issues: :work_items
    }.freeze

    class << self
      def global
        enabled_global_scopes = global_scopes.select do |scope|
          setting_name = scope_to_setting[scope.to_sym] || scope
          ::Gitlab::CurrentSettings.public_send(:"global_search_#{setting_name}_enabled") # rubocop:disable GitlabSecurity/PublicSend -- needed for application settings
        end

        ALWAYS_ALLOWED_SCOPES + enabled_global_scopes
      end

      def group
        ALWAYS_ALLOWED_SCOPES + global_scopes
      end

      def project
        PROJECT_SCOPES
      end

      private

      def global_scopes
        GLOBAL_SCOPES
      end

      def scope_to_setting
        SCOPE_TO_SETTING
      end
    end
  end
end

Search::Scope.prepend_mod
