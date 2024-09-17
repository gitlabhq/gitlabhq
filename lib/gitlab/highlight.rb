# frozen_string_literal: true

module Gitlab
  class Highlight
    def self.highlight(blob_name, blob_content, language: nil, plain: false, context: {}, used_on: :blob)
      new(blob_name, blob_content, language: language)
        .highlight(blob_content, continue: false, plain: plain, context: context, used_on: used_on)
    end

    def self.too_large?(size)
      size.to_i > self.file_size_limit
    end

    attr_reader :blob_name

    def initialize(blob_name, blob_content, language: nil)
      @formatter = Rouge::Formatters::HTMLGitlab
      @language = language
      @blob_name = blob_name
      @blob_content = blob_content
      @gitlab_highlight_usage_counter = Gitlab::Metrics.counter(
        :gitlab_highlight_usage,
        'The number of times Gitlab::Highlight is used'
      )
    end

    def highlight(text, continue: false, plain: false, context: {}, used_on: :blob)
      @context = context

      plain ||= self.class.too_large?(text.length)

      highlighted_text = highlight_text(text, continue: continue, plain: plain, used_on: used_on)
      highlighted_text = link_dependencies(text, highlighted_text, used_on: used_on) if blob_name
      highlighted_text
    end

    def lexer
      @lexer ||= custom_language || begin
        Rouge::Lexer.guess(filename: @blob_name, source: @blob_content).new
      rescue Rouge::Guesser::Ambiguous => e
        e.alternatives.min_by(&:tag)
      end
    end

    def self.file_size_limit
      Gitlab.config.extra['maximum_text_highlight_size_kilobytes'].kilobytes
    end

    private

    attr_reader :context

    def custom_language
      return unless @language

      Rouge::Lexer.find_fancy(@language)
    end

    def highlight_text(text, continue: true, plain: false, used_on: :blob)
      @gitlab_highlight_usage_counter.increment(used_on: used_on)

      if plain
        highlight_plain(text)
      else
        highlight_rich(text, continue: continue)
      end
    end

    def highlight_plain(text)
      @formatter.format(Rouge::Lexers::PlainText.lex(text), **context).html_safe
    end

    def highlight_rich(text, continue: true)
      tag = lexer.tag
      tokens = lexer.lex(text, continue: continue)
      Gitlab::RenderTimeout.timeout { @formatter.format(tokens, **context, tag: tag).html_safe }
    rescue Timeout::Error => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
      highlight_plain(text)
    rescue StandardError
      highlight_plain(text)
    end

    def link_dependencies(text, highlighted_text, used_on: :blob)
      Gitlab::DependencyLinker.link(blob_name, text, highlighted_text, used_on: used_on)
    end
  end
end
