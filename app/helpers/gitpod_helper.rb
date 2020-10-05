# frozen_string_literal: true

module GitpodHelper
  def gitpod_enable_description
    link_start = '<a href="https://gitpod.io/" target="_blank" rel="noopener noreferrer">'.html_safe
    link_end = "#{sprite_icon('external-link', size: 12, css_class: 'ml-1 vertical-align-center')}</a>".html_safe

    s_('Enable %{link_start}Gitpod%{link_end} integration to launch a development environment in your browser directly from GitLab.').html_safe % { link_start: link_start, link_end: link_end }
  end
end
