# frozen_string_literal: true

module Gitlab
  class Unicode
    # Regular expression for identifying bidirectional control
    # characters in UTF-8 strings
    #
    # Documentation on how this works:
    # https://idiosyncratic-ruby.com/41-proper-unicoding.html
    BIDI_REGEXP = /\p{Bidi Control}/

    # Regular expression for identifying space characters
    #
    # In web browsers space characters can be confused with simple
    # spaces which may be misleading
    SPACE_REGEXP = /\p{Space_Separator}/

    DANGEROUS_CHARS = Regexp.union(
      /[\p{Cc}&&[^\t\n\r]]/, # All control chars except tab, LF, CR
      /\u00AD/,              # Soft hyphen
      /\u200B/,              # ZWSP
      /[\u202A-\u202E]/,     # Bidi overrides
      /\u2060/,              # Word joiner
      /[\u2066-\u2069]/,     # Bidi isolates
      /\uFEFF/,              # BOM
      /[\uFFF9-\uFFFB]/,     # Annotations
      /\uFFFC/,              # Object replacement
      /[\u2062-\u2064]/,     # Invisible math operators
      /[\u{E0000}-\u{E01EF}]/, # Tag characters + Variation Selectors Supplement
      /[\u2028-\u2029]/ # Line/paragraph separators
    ).freeze

    class << self
      # Warning message used to highlight bidi characters in the GUI
      def bidi_warning
        _("Potentially unwanted character detected: Unicode BiDi Control")
      end
    end
  end
end
