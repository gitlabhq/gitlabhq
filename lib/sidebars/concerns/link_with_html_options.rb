# frozen_string_literal: true

module Sidebars
  module Concerns
    module LinkWithHtmlOptions
      # add on specific items as the pertain to `link_to` objects specifically
      def link_html_options
        container_html_options.tap do |html_options|
          html_options[:class] = [*html_options[:class], 'gl-link'].join(' ')
        end
      end
    end
  end
end
