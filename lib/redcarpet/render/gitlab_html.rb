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

    if Pygments::Lexer.find(language)
      Pygments.highlight(code, options.merge(lexer: language.downcase))
    else
      Pygments.highlight(code, options)
    end
  end

  def postprocess(full_document)
    h.gfm(full_document)
  end
end
