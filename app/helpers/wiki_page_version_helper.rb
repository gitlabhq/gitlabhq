# frozen_string_literal: true

module WikiPageVersionHelper
  include SafeFormatHelper

  def wiki_page_version_author_url(wiki_page_version)
    user = wiki_page_version.author
    user.nil? ? "mailto:#{wiki_page_version.author_email}" : Gitlab::UrlBuilder.build(user)
  end

  def wiki_page_version_author_avatar(wiki_page_version)
    image_tag(avatar_icon_for_email(wiki_page_version.author_email, 24), class: "avatar s24 float-none gl-mr-0!")
  end

  def wiki_page_version_author_header(wiki_page_version)
    safe_format(s_("Wiki|Last edited by %{link_start}%{span_start}%{name}%{span_end}%{link_end}"),
      tag_pair(content_tag(:span, '', class: 'gl-font-bold gl-text-black-normal'), :span_start, :span_end),
      tag_pair(link_to('', wiki_page_version_author_url(wiki_page_version)), :link_start, :link_end),
      name: wiki_page_version.author_name
    )
  end
end
