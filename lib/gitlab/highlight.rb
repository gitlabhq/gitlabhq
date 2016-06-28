module Gitlab
  class Highlight
    def self.highlight(blob_name, blob_content, repository: nil, nowrap: true, plain: false)
      new(blob_name, blob_content, nowrap: nowrap, repository: repository).
        highlight(blob_content, continue: false, plain: plain)
    end

    def self.highlight_lines(repository, ref, file_name)
      blob = repository.blob_at(ref, file_name)
      return [] unless blob

      blob.load_all_data!(repository)
      highlight(file_name, blob.data, repository: repository).lines.map!(&:html_safe)
    end

    attr_reader :lexer
    def initialize(blob_name, blob_content, repository: nil, nowrap: true)
      @blob_name = blob_name
      @blob_content = blob_content
      @repository = repository
      @formatter = rouge_formatter(nowrap: nowrap)

      @lexer = custom_language || begin
        Rouge::Lexer.guess(filename: blob_name, source: blob_content).new
      rescue Rouge::Lexer::AmbiguousGuess => e
        e.alternatives.sort_by(&:tag).first
      end
    end

    def highlight(text, continue: true, plain: false)
      if plain
        @formatter.format(Rouge::Lexers::PlainText.lex(text)).html_safe
      else
        @formatter.format(@lexer.lex(text, continue: continue)).html_safe
      end
    rescue
      @formatter.format(Rouge::Lexers::PlainText.lex(text)).html_safe
    end

    private

    def custom_language
      language_name = @repository && @repository.gitattribute(@blob_name, 'gitlab-language')

      return nil unless language_name

      Rouge::Lexer.find_fancy(language_name)
    end

    def rouge_formatter(options = {})
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
