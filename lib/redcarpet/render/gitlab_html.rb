class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML

  attr_reader :template
  alias_method :h, :template

  def initialize(template, options = {})
    @template = template
    @project = @template.instance_variable_get("@project")
    super options
  end

  def block_code(code, language)
    options = { options: {encoding: 'utf-8'} }
    options.merge!(lexer: language.downcase) if Pygments::Lexer.find(language)

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

  def postprocess(full_document)
    h.gfm(full_document)
  end
end
