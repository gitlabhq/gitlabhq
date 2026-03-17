# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Lookbook
        # Prevents Lookbook `@param` annotations from exposing URL/link
        # parameters as user-editable inputs, which can lead to XSS via
        # `javascript:` URIs.
        #
        # Instead, hardcode URL values (e.g., `"#"`) in the preview method
        # body.
        #
        # @example
        #
        #   # bad
        #   # @param href url
        #   def default(href: "#")
        #     render Component.new(href: href)
        #   end
        #
        #   # bad
        #   # @param button_link text
        #   def default(button_link: "https://example.com")
        #     render Component.new(button_link: button_link)
        #   end
        #
        #   # good
        #   def default
        #     render Component.new(href: "#")
        #   end
        #
        class NoUrlParamInPreview < RuboCop::Cop::Base
          MSG = 'Do not expose URL/link parameters via `@param` in Lookbook previews. ' \
            'Hardcode the value (e.g., `"#"`) to prevent XSS.'

          # Matches: @param <name> url
          URL_TYPE_PATTERN = /\A@param\s+\S+\s+url\b/

          # Matches: @param <name_containing_href_link_or_url> <any_type>
          URL_NAME_PATTERN = /\A@param\s+\S*(href|link|url)\S*\s+/

          def on_new_investigation
            super

            processed_source.comments.each do |comment|
              text = comment.text.sub(/\A#\s*/, '')
              next unless URL_TYPE_PATTERN.match?(text) || URL_NAME_PATTERN.match?(text)

              add_offense(comment)
            end
          end
        end
      end
    end
  end
end
