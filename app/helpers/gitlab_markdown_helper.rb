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

    escaped_body = if body =~ /^\<img/
                     body
                   else
                     escape_once(body)
                   end

    gfm_body = gfm(escaped_body, html_options)

    gfm_body.gsub!(%r{<a.*?>.*?</a>}m) do |match|
      "</a>#{match}#{link_to("", url, html_options)[0..-5]}" # "</a>".length +1
    end

    link_to(gfm_body.html_safe, url, html_options)
  end

  def markdown(text)
    unless @markdown
      gitlab_renderer = Redcarpet::Render::GitlabHTML.new(self,
                          # see https://github.com/vmg/redcarpet#darling-i-packed-you-a-couple-renderers-for-lunch-
                          filter_html: true,
                          with_toc_data: true,
                          hard_wrap: true,
                          safe_links_only: true)
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

    @markdown.render(text).html_safe
  end

  def render_wiki_content(wiki_page)
    if wiki_page.format == :markdown
      markdown(wiki_page.content)
    else
      wiki_page.formatted_content.html_safe
    end
  end

  def create_relative_links(text, project_path_with_namespace, ref, wiki = false)
    links = extract_paths(text)
    links.each do |string|
      new_link = new_link(project_path_with_namespace, string, ref)
      text.gsub!("](#{string})", "](/#{new_link})")
    end
    text
  end

  def extract_paths(text)
    text.split("\n").map { |a| a.scan(/\]\(([^(]+)\)/) }.reject{|b| b.empty? }.flatten.reject{|c| c.include?("http" || "www")}
  end

  def new_link(path_with_namespace, string, ref)
    [
      path_with_namespace,
      path_with_ref(string, ref),
      string
    ].compact.join("/")
  end

  def path_with_ref(string, ref)
    if File.exists?(Rails.root.join(string))
      "#{local_path(string)}/#{correct_ref(ref)}"
    else
      "wikis"
    end
  end

  def local_path(string)
    File.directory?(Rails.root.join(string)) ? "tree":"blob"
  end

  def correct_ref(ref)
    ref ? ref:'master'
  end
end
