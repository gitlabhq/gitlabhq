# frozen_string_literal: true

module SourcegraphHelper
  def sourcegraph_url_message
    message =
      if Gitlab::CurrentSettings.sourcegraph_url_is_com?
        s_('SourcegraphPreferences|Uses %{linkStart}Sourcegraph.com%{linkEnd}.')
      else
        s_('SourcegraphPreferences|Uses a custom %{linkStart}Sourcegraph instance%{linkEnd}.')
      end

    experimental_message =
      if Gitlab::CurrentSettings.sourcegraph_public_only
        s_("SourcegraphPreferences|This feature is experimental and limited to public projects.")
      else
        s_("SourcegraphPreferences|This feature is experimental.")
      end

    "#{message} #{experimental_message}"
  end
end
