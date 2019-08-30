# frozen_string_literal: true

module ExternalLinkHelper
  def external_link(body, url)
    link_to url, target: '_blank', rel: 'noopener noreferrer' do
      "#{body} #{icon('external-link')}".html_safe
    end
  end
end
