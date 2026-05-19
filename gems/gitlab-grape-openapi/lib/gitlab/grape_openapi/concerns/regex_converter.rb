# frozen_string_literal: true

require "js_regex"

module Gitlab
  module GrapeOpenapi
    module Concerns
      # Converts Ruby Regexp objects into ECMA-262 (JavaScript) compatible
      # pattern strings for use in OpenAPI `pattern` schema fields.
      #
      # OpenAPI requires `pattern` values to be valid ECMA-262 regular
      # expressions, but Ruby RegExes routinely contain constructs that ECMA-262
      # cannot parse: \A / \z anchors, inline option groups like (?i-mx:...),
      # POSIX classes, etc. js_regex translates these into JS-compatible equivalents.
      #
      # The Ruby /i flag is folded into the pattern itself (via character class
      # expansion) so the resulting pattern carries no flags, which OpenAPI's
      # flag-less `pattern` field requires
      module RegexConverter
        # js_regex's `target:` controls which ECMAScript version's regex
        # features it will emit. ES2018 is the newest target the gem
        # supports (as of 3.14.0); earlier targets like the default (ES5)
        # silently drop lookbehinds, changing the semantics of any Ruby
        # regex that relies on them
        JS_REGEX_TARGET = 'ES2018'

        def regexp_to_pattern(value)
          regexp = extract_regexp(value)
          return unless regexp

          JsRegex.new(inline_case_insensitivity(regexp), target: JS_REGEX_TARGET).source
        end

        private

        # Grape stores the validation's `:options` as the Regexp itself for
        # `regexp: /.../`, or as a Hash `{ value: /.../, message: '...' }` for the
        # long form. Pull the Regexp out of either shape
        def extract_regexp(value)
          return value if value.is_a?(Regexp)

          value[:value] if value.is_a?(Hash) && value[:value].is_a?(Regexp)
        end

        # js_regex bakes case-insensitivity into character classes only when /i
        # appears as an inline group; an outer /i flag survives as a JS-level
        # option that we cannot represent in OpenAPI. Wrap the source in (?i:...)
        # and drop the outer flag so js_regex expands the character classes
        def inline_case_insensitivity(regexp)
          return regexp if (regexp.options & Regexp::IGNORECASE).zero?

          remaining_options = regexp.options & ~Regexp::IGNORECASE
          Regexp.new("(?i:#{regexp.source})", remaining_options)
        end
      end
    end
  end
end
