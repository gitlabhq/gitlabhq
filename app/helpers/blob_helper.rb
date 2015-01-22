module BlobHelper
  def highlight(blob_name, blob_content, nowrap = false)
    formatter = Rugments::Formatters::HTML.new(
      nowrap: nowrap,
      cssclass: 'code highlight',
      lineanchors: true,
      lineanchorsid: 'LC'
    )

    begin
      lexer = Rugments::Lexer.guess(filename: blob_name, source: blob_content)
    rescue Rugments::Lexer::AmbiguousGuess
      lexer = Rugments::Lexers::PlainText
    end

    formatter.format(lexer.lex(blob_content)).html_safe
  end

  def no_highlight_files
    %w(credits changelog copying copyright license authors)
  end
end
