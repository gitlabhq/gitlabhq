module GitlabMarkdownHelper
  include Gitlab::Markdown

  # Use this in places where you would normally use link_to(gfm(...), ...).
  #
  # It solves a problem occurring with nested links (i.e.
  # "<a>outer text <a>gfm ref</a> more outer text</a>"). This will not be
  # interpreted as intended. Browsers will parse something like
  # "<a>outer text </a><a>gfm ref</a> more outer text" (notice the last part is
  # not linked any more). link_to_gfm corrects that. It wraps all parts to
  # explicitly produce the correct linking behavior (i.e.
  # "<a>outer text </a><a>gfm ref</a><a> more outer text</a>").
  def link_to_gfm(body, url, html_options = {})
    return "" if body.blank?

    gfm_body = gfm(escape_once(body), html_options)

    gfm_body.gsub!(%r{<a.*?>.*?</a>}m) do |match|
      "</a>#{match}#{link_to("", url, html_options)[0..-5]}" # "</a>".length +1
    end

    link_to(gfm_body.html_safe, url, html_options)
  end

  def markdown(text)
    unless @markdown

      # If the user wants TOC we run a Render::HTML_TOC
      # See http://dev.af83.com/2012/02/27/howto-extend-the-redcarpet2-markdown-lib.html
      toc = nil
      if text.match("~toc~") != nil
         html_toc = Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC, space_after_headers: true)
         toc = html_toc.render(text)

         text["~toc~"]= ""
      end

      gitlab_renderer = Redcarpet::Render::GitlabHTML.new(self,
                          # see https://github.com/vmg/redcarpet#darling-i-packed-you-a-couple-renderers-for-lunch-
                          filter_html: false,
                          with_toc_data: true,
                          hard_wrap: true)
      @markdown = Redcarpet::Markdown.new(gitlab_renderer,
                      # see https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
                      no_intra_emphasis: true,
                      tables: true,
                      fenced_code_blocks: true,
                      autolink: true,
                      strikethrough: true,
                      lax_html_blocks: true,
                      space_after_headers: true,
                      superscript: true)
    end

    if toc == nil
    @markdown.render(text).html_safe
    else
      (toc + @markdown.render(text)).html_safe
    end
  end
end
