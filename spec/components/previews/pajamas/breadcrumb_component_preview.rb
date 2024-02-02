# frozen_string_literal: true

module Pajamas
  class BreadcrumbComponentPreview < ViewComponent::Preview
    # Breadcrumb
    # ----
    # See its design reference [here](https://design.gitlab.com/components/breadcrumb).
    #
    # @param text text
    # @param href url
    def default(text: 'My Project', href: '#')
      render Pajamas::BreadcrumbComponent.new do |c|
        c.with_item(text: 'Home', href: '/')
        c.with_item(text: 'My Group', href: '#')
        c.with_item(text: text, href: href)
        c.with_item(text: 'Issues', href: '#')
        c.with_item(text: '#1234', href: '#')
      end
    end
  end
end
