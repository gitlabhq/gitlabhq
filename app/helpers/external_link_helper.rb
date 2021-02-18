# frozen_string_literal: true

module ExternalLinkHelper
  def external_link(body, url, options = {})
    link_to url, { target: '_blank', rel: 'noopener noreferrer' }.merge(options) do
      "#{body}#{sprite_icon('external-link', css_class: 'gl-ml-1')}".html_safe
    end
  end
end
