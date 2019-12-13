# frozen_string_literal: true

module Gitlab
  class Highlight
    TIMEOUT_BACKGROUND = 30.seconds
    TIMEOUT_FOREGROUND = 3.seconds
    MAXIMUM_TEXT_HIGHLIGHT_SIZE = 1.megabyte

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
      plain ||= text.length > MAXIMUM_TEXT_HIGHLIGHT_SIZE

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
      return unless @language

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
      tag = lexer.tag
      tokens = lexer.lex(text, continue: continue)
      Timeout.timeout(timeout_time) { @formatter.format(tokens, tag: tag).html_safe }
    rescue Timeout::Error => e
      Gitlab::Sentry.track_and_raise_for_dev_exception(e)
      highlight_plain(text)
    rescue
      highlight_plain(text)
    end

    def timeout_time
      Gitlab::Runtime.sidekiq? ? TIMEOUT_BACKGROUND : TIMEOUT_FOREGROUND
    end

    def link_dependencies(text, highlighted_text)
      Gitlab::DependencyLinker.link(blob_name, text, highlighted_text)
    end
  end
end
