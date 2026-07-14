# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Encourages the use of `Gitlab::Json::SafeParser.parse` over `Gitlab::Json.parse`
      # for parsing untrusted JSON input with built-in size and depth limits.
      #
      # `SafeParser` provides protection against:
      # - Deeply nested structures (DoS via stack exhaustion)
      # - Extremely large arrays or hashes (memory exhaustion)
      # - Oversized JSON payloads (memory exhaustion)
      #
      # @example
      #   # bad - no arguments beyond payload -> corrected to SafeParser.parse
      #
      #   Gitlab::Json.parse(user_input)
      #   Gitlab::Json.parse(request.body.read)
      #   ::Gitlab::Json.parse(params[:data])
      #
      #   # good (autocorrected)
      #
      #   Gitlab::Json::SafeParser.parse(user_input)
      #   Gitlab::Json::SafeParser.parse(request.body.read)
      #   ::Gitlab::Json::SafeParser.parse(params[:data])
      #
      #   # bad - extra arguments present -> corrected to Gitlab::Json.safe_parse
      #   # (SafeParser.parse only accepts parse-limit keys and would raise
      #   # UnknownConfigurationError for JSON options like `symbolize_names:`.)
      #
      #   Gitlab::Json.parse(data, symbolize_names: true)
      #   Gitlab::Json.parse(data, legacy_mode: true)
      #
      #   # good (autocorrected)
      #
      #   Gitlab::Json.safe_parse(data, symbolize_names: true)
      #   Gitlab::Json.safe_parse(data, legacy_mode: true)
      #
      #   # also good - already using `Gitlab::Json.safe_parse`
      #
      #   Gitlab::Json.safe_parse(data)
      #   Gitlab::Json.safe_parse(data, parse_limits: { max_depth: 10 })
      #
      class JsonSafeParse < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = <<~TEXT.chomp
          Prefer `Gitlab::Json::SafeParser.parse` over `Gitlab::Json.parse` when parsing untrusted input. \
          See https://docs.gitlab.com/development/secure_coding_guidelines/#json-parsing
        TEXT

        RESTRICT_ON_SEND = %i[parse parse! load decode].freeze

        # @!method gitlab_json_call(node)
        def_node_matcher :gitlab_json_call, <<~PATTERN
          (send
            (const
              (const {nil? (cbase)} :Gitlab)
              :Json)
            ${:parse :parse! :load :decode}
            $...)
        PATTERN

        def on_send(node)
          method_name, args = gitlab_json_call(node)
          return unless method_name

          add_offense(node) do |corrector|
            corrector.replace(node, replacement(node, args))
          end
        end
        alias_method :on_csend, :on_send

        private

        def replacement(node, arg_nodes)
          arg_source = arg_nodes.map(&:source).join(", ")
          "#{cbase_prefix(node)}#{target(arg_nodes)}(#{arg_source})"
        end

        def target(arg_nodes)
          if arg_nodes.length <= 1
            "Gitlab::Json::SafeParser.parse"
          else
            "Gitlab::Json.safe_parse"
          end
        end

        def cbase_prefix(node)
          return "::" if node.source_range.source_buffer.name.include?('/ee/')

          ""
        end
      end
    end
  end
end
