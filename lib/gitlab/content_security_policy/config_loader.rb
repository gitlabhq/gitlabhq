# frozen_string_literal: true

module Gitlab
  module ContentSecurityPolicy
    class ConfigLoader
      DIRECTIVES = %w(base_uri child_src connect_src default_src font_src
                      form_action frame_ancestors frame_src img_src manifest_src
                      media_src object_src report_uri script_src style_src worker_src).freeze

      def self.default_settings_hash
        {
          'enabled' => false,
          'report_only' => false,
          'directives' => DIRECTIVES.each_with_object({}) { |directive, hash| hash[directive] = nil }
        }
      end

      def initialize(csp_directives)
        @csp_directives = HashWithIndifferentAccess.new(csp_directives)
      end

      def load(policy)
        DIRECTIVES.each do |directive|
          arguments = arguments_for(directive)

          next unless arguments.present?

          policy.public_send(directive, *arguments) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      private

      def arguments_for(directive)
        arguments = @csp_directives[directive.to_s]

        return unless arguments.present? && arguments.is_a?(String)

        arguments.strip.split(' ').map(&:strip)
      end
    end
  end
end
