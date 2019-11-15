# frozen_string_literal: true

module SourcegraphHelper
  def sourcegraph_url_message
    link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: Gitlab::CurrentSettings.sourcegraph_url }
    link_end = "#{sprite_icon('external-link', size: 12, css_class: 'ml-1 vertical-align-center')}</a>".html_safe

    message =
      if Gitlab::CurrentSettings.sourcegraph_url_is_com?
        s_('SourcegraphPreferences|Uses %{link_start}Sourcegraph.com%{link_end}.').html_safe
      else
        s_('SourcegraphPreferences|Uses a custom %{link_start}Sourcegraph instance%{link_end}.').html_safe
      end

    message % { link_start: link_start, link_end: link_end }
  end

  def sourcegraph_experimental_message
    if Gitlab::Sourcegraph.feature_conditional?
      s_("SourcegraphPreferences|This feature is experimental and currently limited to certain projects.")
    elsif Gitlab::CurrentSettings.sourcegraph_public_only
      s_("SourcegraphPreferences|This feature is experimental and limited to public projects.")
    else
      s_("SourcegraphPreferences|This feature is experimental.")
    end
  end
end
