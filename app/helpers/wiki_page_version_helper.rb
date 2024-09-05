# frozen_string_literal: true

module WikiPageVersionHelper
  include SafeFormatHelper

  def wiki_page_version_author_url(wiki_page_version)
    user = wiki_page_version.author
    user.nil? ? "mailto:#{wiki_page_version.author_email}" : Gitlab::UrlBuilder.build(user)
  end

  def wiki_page_version_author_avatar(wiki_page_version)
    image_tag(avatar_icon_for_email(wiki_page_version.author_email, 24), class: "avatar s24 float-none !gl-mr-0")
  end
end
