class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML

  attr_reader :template
  alias_method :h, :template

  def initialize(template, options = {})
    @template = template
    @project = @template.instance_variable_get("@project")
    super options
  end

  def block_code(code, language)
    if Pygments::Lexer.find(language)
      Pygments.highlight(code, lexer: language, options: {encoding: 'utf-8'})
    else
      Pygments.highlight(code, options: {encoding: 'utf-8'})
    end
  end

  def postprocess(full_document)
    h.gfm(full_document)
  end
end
