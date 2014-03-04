class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML

  attr_reader :template
  alias_method :h, :template

  def initialize(template, options = {})
    @template = template
    @project = @template.instance_variable_get("@project")
    @ref = @template.instance_variable_get("@ref")
    @request_path = @template.instance_variable_get("@path")
    @options = options.dup
    super options
  end

  def block_code(code, language)
    # New lines are placed to fix an rendering issue
    # with code wrapped inside <h1> tag for next case:
    #
    # # Title kinda h1
    #
    #     ruby code here
    #
    <<-HTML

<div class="highlighted-data #{h.user_color_scheme_class}">
  <div class="highlight">
    <pre><code class="#{language}">#{h.send(:html_escape, code)}</code></pre>
  </div>
</div>

    HTML
  end

  def link(link, title, content)
    h.link_to_gfm(content, link, title: title)
  end

  def header(text, level)
    if @options[:no_header_anchors]
      "<h#{level}>#{text}</h#{level}>"
    else
      id = ActionController::Base.helpers.strip_tags(h.gfm(text)).downcase() \
          .gsub(/[^a-z0-9_-]/, '-').gsub(/-+/, '-').gsub(/^-/, '').gsub(/-$/, '')
      "<h#{level} id=\"#{id}\">#{text}<a href=\"\##{id}\"></a></h#{level}>"
    end
  end

  def preprocess(full_document)
    if @project
      h.create_relative_links(full_document, @project, @ref, @request_path, is_wiki?)
    else
      full_document
    end
  end

  def postprocess(full_document)
    h.gfm(full_document)
  end

  def is_wiki?
    @template.instance_variable_get("@wiki")
  end
end
