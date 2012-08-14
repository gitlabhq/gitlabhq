module GitlabMarkdownHelper
  def gfm(text, html_options = {})
    return text if text.nil?
    return text if @project.nil?

    # Extract pre blocks
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

  # circumvents nesting links, which will behave bad in browsers
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
