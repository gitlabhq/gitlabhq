# frozen_string_literal: true

module WikiPageVersionHelper
  def wiki_page_version_author_url(wiki_page_version)
    user = wiki_page_version.author
    user.nil? ? "mailto:#{wiki_page_version.author_email}" : Gitlab::UrlBuilder.build(user)
  end

  def wiki_page_version_author_avatar(wiki_page_version)
    image_tag(avatar_icon_for_email(wiki_page_version.author_email, 24), class: "avatar s24 float-none gl-mr-0!")
  end

  def wiki_page_version_author_header(wiki_page_version)
    avatar = wiki_page_version_author_avatar(wiki_page_version)
    name = "<strong>".html_safe + wiki_page_version.author_name + "</strong>".html_safe
    link_start = "<a href='".html_safe + wiki_page_version_author_url(wiki_page_version) + "'>".html_safe

    html_escape(_("Last edited by %{link_start}%{avatar} %{name}%{link_end}")) % { avatar: avatar, name: name, link_start: link_start, link_end: '</a>'.html_safe }
  end
end
