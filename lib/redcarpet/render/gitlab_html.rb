require 'active_support/core_ext/string/output_safety'

class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML
  attr_reader :template
  alias_method :h, :template

  def initialize(template, color_scheme, options = {})
    @template = template
    @color_scheme = color_scheme
    @project = @template.instance_variable_get("@project")
    @options = options.dup

    super(options)
  end

  def normal_text(text)
    ERB::Util.html_escape_once(text)
  end

  # Stolen from Rugments::Plugins::Redcarpet as this module is not required
  # from Rugments's gem root.
  def block_code(code, language)
    lexer = Rugments::Lexer.find_fancy(language, code) || Rugments::Lexers::PlainText

    # XXX HACK: Redcarpet strips hard tabs out of code blocks,
    # so we assume you're not using leading spaces that aren't tabs,
    # and just replace them here.
    if lexer.tag == 'make'
      code.gsub!(/^    /, "\t")
    end

    formatter = Rugments::Formatters::HTML.new(
      cssclass: "code highlight #{@color_scheme} #{lexer.tag}"
    )
    formatter.format(lexer.lex(code))
  end

  def postprocess(full_document)
    h.gfm_with_options(full_document, @options)
  end
end
