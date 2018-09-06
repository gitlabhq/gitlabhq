module Gitlab
  class Highlight
    def self.highlight(blob_name, blob_content, language: nil, plain: false)
      new(blob_name, blob_content, language: language)
        .highlight(blob_content, continue: false, plain: plain)
    end

    attr_reader :blob_name

    def initialize(blob_name, blob_content, language: nil)
      @formatter = Rouge::Formatters::HTMLGitlab
      @language = language
      @blob_name = blob_name
      @blob_content = blob_content
    end

    def highlight(text, continue: true, plain: false)
      highlighted_text = highlight_text(text, continue: continue, plain: plain)
      highlighted_text = link_dependencies(text, highlighted_text) if blob_name
      highlighted_text
    end

    def lexer
      @lexer ||= custom_language || begin
        Rouge::Lexer.guess(filename: @blob_name, source: @blob_content).new
      rescue Rouge::Guesser::Ambiguous => e
        e.alternatives.sort_by(&:tag).first
      end
    end

    private

    def custom_language
      return nil unless @language

      Rouge::Lexer.find_fancy(@language)
    end

    def highlight_text(text, continue: true, plain: false)
      if plain
        highlight_plain(text)
      else
        highlight_rich(text, continue: continue)
      end
    end

    def highlight_plain(text)
      @formatter.format(Rouge::Lexers::PlainText.lex(text)).html_safe
    end

    def highlight_rich(text, continue: true)
      @formatter.format(lexer.lex(text, continue: continue), tag: lexer.tag).html_safe
    rescue
      highlight_plain(text)
    end

    def link_dependencies(text, highlighted_text)
      Gitlab::DependencyLinker.link(blob_name, text, highlighted_text)
    end
  end
end
