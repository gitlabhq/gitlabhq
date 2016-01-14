module Gitlab
  class Highlight
    def self.highlight(blob_name, blob_content, nowrap: true, continue: false)
      formatter = rouge_formatter(nowrap: nowrap)

      lexer = Rouge::Lexer.guess(filename: blob_name, source: blob_content).new rescue Rouge::Lexers::PlainText
      formatter.format(lexer.lex(blob_content, continue: continue)).html_safe
    end

    private

    def self.rouge_formatter(options = {})
      options = options.reverse_merge(
        nowrap: true,
        cssclass: 'code highlight',
        lineanchors: true,
        lineanchorsid: 'LC'
      )

      Rouge::Formatters::HTMLGitlab.new(options)
    end
  end
end
