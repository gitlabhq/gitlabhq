# frozen_string_literal: true

module RuboCop
  module Cop
    # Check for symlinks when extracting files to avoid arbitrary file reading.
    class FileDecompression < RuboCop::Cop::Base
      MSG = <<~EOF
      While extracting files check for symlink to avoid arbitrary file reading.
      https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6132
      EOF

      def_node_matcher :system?, <<~PATTERN
        (send {nil? | const} {:system | :exec | :spawn | :popen}
          (str $_))
      PATTERN

      def_node_matcher :subshell?, <<~PATTERN
        (xstr
          (str $_))
      PATTERN

      FORBIDDEN_COMMANDS = %w[gunzip gzip zip tar].freeze

      def on_xstr(node)
        subshell?(node) do |match|
          add_offense(node, message: MSG) if forbidden_command?(match)
        end
      end

      def on_send(node)
        system?(node) do |match|
          add_offense(node, message: MSG) if forbidden_command?(match)
        end
      end

      private

      def forbidden_command?(cmd)
        FORBIDDEN_COMMANDS.any? do |forbidden|
          cmd.match?(forbidden)
        end
      end
    end
  end
end
