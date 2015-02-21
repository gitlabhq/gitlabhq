class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML

  attr_reader :template
  alias_method :h, :template

  def initialize(template, options = {})
    @template = template
    @project = @template.instance_variable_get("@project")
    @options = options.dup
    super options
  end

  # If project has issue number 39, apostrophe will be linked in
  # regular text to the issue as Redcarpet will convert apostrophe to
  # #39;
  # We replace apostrophe with right single quote before Redcarpet
  # does the processing and put the apostrophe back in postprocessing.
  # This only influences regular text, code blocks are untouched.
  def normal_text(text)
    return text unless text.present?
    text.gsub("'", "&rsquo;")
  end

  # Stolen from Rugments::Plugins::Redcarpet as this module is not required
  # from Rugments's gem root.
  def block_code(code, language)
    lexer = Rugments::Lexer.find_fancy(language, code) || Rugments::Lexers::PlainText

    # XXX HACK: Redcarpet strips hard tabs out of code blocks,
    # so we assume you're not using leading spaces that aren't tabs,
    # and just replace them here.
    if lexer.tag == 'make'
      code.gsub! /^    /, "\t"
    end

    formatter = Rugments::Formatters::HTML.new(
      cssclass: "code highlight white #{lexer.tag}"
    )
    formatter.format(lexer.lex(code))
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

  def postprocess(full_document)
    full_document.gsub!("&rsquo;", "'")
    unless @template.instance_variable_get("@project_wiki") || @project.nil?
      full_document = h.create_relative_links(full_document)
    end
    h.gfm_with_options(full_document, @options)
  end
end
