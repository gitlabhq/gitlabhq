# frozen_string_literal: true

# Starting with Rails 5, Rails tries to determine the request format based on
# the extension of the full URL path if no explicit `format` param or `Accept`
# header is provided, like when simply browsing to a page in your browser.
#
# This is undesirable in GitLab, because many of our paths will end in a ref or
# blob name that can end with any extension, while these pages should still be
# presented as HTML unless otherwise specified.

# We override `format_from_path_extension` to disable this behavior.

module ActionDispatch
  module Http
    module MimeNegotiation
      def format_from_path_extension
        nil
      end
    end
  end
end
