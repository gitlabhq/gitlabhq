# frozen_string_literal: true

module Sidebars
  module ContainerWithHtmlOptions
    # The attributes returned from this method
    # will be applied to helper methods like
    # `link_to` or the div containing the container.
    def container_html_options
      {
        title: title
      }.merge(extra_container_html_options)
    end

    # Classes will override mostly this method
    # and not `container_html_options`.
    def extra_container_html_options
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
