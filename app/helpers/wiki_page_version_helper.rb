# frozen_string_literal: true

module WikiPageVersionHelper
  include SafeFormatHelper

  def wiki_page_version_author_url(wiki_page_version)
    user = wiki_page_version.author
    user.nil? ? "mailto:#{wiki_page_version.author_email}" : Gitlab::UrlBuilder.build(user)
  end
end
