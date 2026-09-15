# frozen_string_literal: true

module Gitlab
  class Unicode
    # These explicit sets are performance snapshots of Ruby's Unicode properties.
    # spec/lib/gitlab/unicode_spec.rb detects drift when Ruby's Unicode data changes.
    NON_ASCII_SPACE_CHARACTERS = "\u00A0\u1680\u2000\u2001\u2002\u2003\u2004\u2005" \
      "\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000"
    NON_ASCII_SPACE_REGEXP = /[\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]/
    BIDI_CONTROL_REGEXP = /[\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]/

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
