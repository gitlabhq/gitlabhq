# frozen_string_literal: true

module ProtectedRefNameSanitizer
  def sanitize_name(name)
    name = CGI.unescapeHTML(name)
    name = Sanitize.fragment(name)

    # Sanitize.fragment escapes HTML chars, so unescape again to allow names
    # like `feature->master`
    CGI.unescapeHTML(name)
  end
end
