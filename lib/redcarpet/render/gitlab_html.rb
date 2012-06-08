class Redcarpet::Render::GitlabHTML < Redcarpet::Render::HTML
  def block_code(code, language)
    if Pygments::Lexer.find(language)
      Pygments.highlight(code, :lexer => language, :options => {:encoding => 'utf-8'})
    else
      Pygments.highlight(code, :options => {:encoding => 'utf-8'})
    end
  end
end
