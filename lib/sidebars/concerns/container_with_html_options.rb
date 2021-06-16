# frozen_string_literal: true

module Sidebars
  module Concerns
    module ContainerWithHtmlOptions
      # The attributes returned from this method
      # will be applied to helper methods like
      # `link_to` or the div containing the container.
      def container_html_options
        {
          aria: { label: title }
        }.merge(extra_container_html_options)
      end

      # Classes will override mostly this method
      # and not `container_html_options`.
      def extra_container_html_options
        {}
      end

      # The attributes returned from this method
      # will be applied to helper methods like
      # `link_to` or the div containing the container
      # when it is collapsed.
      def collapsed_container_html_options
        {
          aria: { label: title }
        }.merge(extra_collapsed_container_html_options)
      end

      # Classes should mostly override this method
      # and not `collapsed_container_html_options`.
      def extra_collapsed_container_html_options
        {}
      end

      # Attributes to pass to the html_options attribute
      # in the helper method that sets the active class
      # on each element.
      def nav_link_html_options
        {
          data: {
            track_label: self.class.name.demodulize.underscore
          }
        }.deep_merge(extra_nav_link_html_options)
      end

      # Classes should mostly override this method
      # and not `nav_link_html_options`.
      def extra_nav_link_html_options
        {}
      end

      def title
        raise NotImplementedError
      end

      # The attributes returned from this method
      # will be applied right next to the title,
      # for example in the span that renders the title.
      def title_html_options
        {}
      end

      def link
        raise NotImplementedError
      end
    end
  end
end
