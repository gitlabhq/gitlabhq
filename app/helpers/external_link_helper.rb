# frozen_string_literal: true

module ExternalLinkHelper
  include ActionView::Helpers::TextHelper

  def external_link(body, url, options = {})
    link = link_to url, { target: '_blank', rel: 'noopener noreferrer' }.merge(options) do
      "#{body}#{sprite_icon('external-link', css_class: 'gl-ml-2')}".html_safe
    end
    sanitize(link, tags: %w[a svg use], attributes: %w[target rel data-testid class href].concat(options.stringify_keys.keys))
  end
end
