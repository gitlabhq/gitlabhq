class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML
  def block_code(code, language)
    if Pygments::Lexer.find(language)
      Pygments.highlight(code, :lexer => language)
    else
      Pygments.highlight(code)
    end
  end
end