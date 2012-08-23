module GitlabMarkdownHelper
  # Replaces references (i.e. @abc, #123, !456, ...) in the text with links to
  # the appropriate items in Gitlab.
  #
  # text          - the source text
  # html_options  - extra options for the reference links as given to link_to
  #
  # note: reference links will only be generated if @project is set
  #
  # see Gitlab::Markdown for details on the supported syntax
  def gfm(text, html_options = {})
    return text if text.nil?
    return text if @project.nil?

    # Extract pre blocks so they are not altered
    # from http://github.github.com/github-flavored-markdown/
    extractions = {}
    text.gsub!(%r{<pre>.*?</pre>|<code>.*?</code>}m) do |match|
      md5 = Digest::MD5.hexdigest(match)
      extractions[md5] = match
      "{gfm-extraction-#{md5}}"
    end

    # TODO: add popups with additional information

    parser = Gitlab::Markdown.new(@project, html_options)
    text = parser.parse(text)

    # Insert pre block extractions
    text.gsub!(/\{gfm-extraction-(\h{32})\}/) do
      extractions[$1]
    end

    text.html_safe
  end

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
    gfm_body = gfm(body, html_options)

    gfm_body.gsub!(%r{<a.*?>.*?</a>}m) do |match|
      "</a>#{match}#{link_to("", url, html_options)[0..-5]}" # "</a>".length +1
    end

    link_to(gfm_body.html_safe, url, html_options)
  end

  def markdown(text)
    @__renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::GitlabHTML.new(self, filter_html: true, with_toc_data: true), {
      no_intra_emphasis: true,
      tables: true,
      fenced_code_blocks: true,
      autolink: true,
      strikethrough: true,
      lax_html_blocks: true,
      space_after_headers: true,
      superscript: true
    })

    @__renderer.render(text).html_safe
  end
end
