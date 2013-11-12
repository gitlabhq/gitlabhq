class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML

  attr_reader :template
  alias_method :h, :template

  def initialize(template, options = {})
    @template = template
    @project = @template.instance_variable_get("@project")
    @ref = @template.instance_variable_get("@ref")
    @request_path = @template.instance_variable_get("@path")
    super options
  end

  def block_code(code, language)
    options = { options: {encoding: 'utf-8'} }
    lexer = Pygments::Lexer.find(language) # language can be an alias
    options.merge!(lexer: lexer.aliases[0].downcase) if lexer # downcase is required

    # New lines are placed to fix an rendering issue
    # with code wrapped inside <h1> tag for next case:
    #
    # # Title kinda h1
    #
    #     ruby code here
    #
    <<-HTML

       <div class="#{h.user_color_scheme_class}">#{Pygments.highlight(code, options)}</div>

    HTML
  end

  def link(link, title, content)
    h.link_to_gfm(content, link, title: title)
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
