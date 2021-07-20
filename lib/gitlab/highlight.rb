# frozen_string_literal: true

module Gitlab
  class Highlight
    TIMEOUT_BACKGROUND = 30.seconds
    TIMEOUT_FOREGROUND = 1.5.seconds

    def self.highlight(blob_name, blob_content, language: nil, plain: false)
      new(blob_name, blob_content, language: language)
        .highlight(blob_content, continue: false, plain: plain)
    end

    def self.too_large?(size)
      return false unless size.to_i > self.file_size_limit

      over_highlight_size_limit.increment(source: "file size: #{self.file_size_limit}") if Feature.enabled?(:track_file_size_over_highlight_limit)

      true
    end

    attr_reader :blob_name

    def initialize(blob_name, blob_content, language: nil)
      @formatter = Rouge::Formatters::HTMLGitlab
      @language = language
      @blob_name = blob_name
      @blob_content = blob_content
    end

    def highlight(text, continue: false, plain: false, context: {})
      @context = context

      plain ||= self.class.too_large?(text.length)

      highlighted_text = highlight_text(text, continue: continue, plain: plain)
      highlighted_text = link_dependencies(text, highlighted_text) if blob_name
      highlighted_text
    end

    def lexer
      @lexer ||= custom_language || begin
        Rouge::Lexer.guess(filename: @blob_name, source: @blob_content).new
      rescue Rouge::Guesser::Ambiguous => e
        e.alternatives.min_by(&:tag)
      end
    end

    private

    attr_reader :context

    def self.file_size_limit
      if Feature.enabled?(:one_megabyte_file_size_limit)
        1024.kilobytes
      else
        Gitlab.config.extra['maximum_text_highlight_size_kilobytes']
      end
    end

    private_class_method :file_size_limit

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
      @formatter.format(Rouge::Lexers::PlainText.lex(text), context).html_safe
    end

    def highlight_rich(text, continue: true)
      add_highlight_attempt_metric

      tag = lexer.tag
      tokens = lexer.lex(text, continue: continue)
      Timeout.timeout(timeout_time) { @formatter.format(tokens, context.merge(tag: tag)).html_safe }
    rescue Timeout::Error => e
      add_highlight_timeout_metric

      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
      highlight_plain(text)
    rescue StandardError
      highlight_plain(text)
    end

    def timeout_time
      Gitlab::Runtime.sidekiq? ? TIMEOUT_BACKGROUND : TIMEOUT_FOREGROUND
    end

    def link_dependencies(text, highlighted_text)
      Gitlab::DependencyLinker.link(blob_name, text, highlighted_text)
    end

    def add_highlight_attempt_metric
      return unless Feature.enabled?(:track_highlight_timeouts)

      highlighting_attempt.increment(source: (@language || "undefined"))
    end

    def add_highlight_timeout_metric
      return unless Feature.enabled?(:track_highlight_timeouts)

      highlight_timeout.increment(source: Gitlab::Runtime.sidekiq? ? "background" : "foreground")
    end

    def highlighting_attempt
      @highlight_attempt ||= Gitlab::Metrics.counter(
        :file_highlighting_attempt,
        'Counts the times highlighting has been attempted on a file'
      )
    end

    def highlight_timeout
      @highlight_timeout ||= Gitlab::Metrics.counter(
        :highlight_timeout,
        'Counts the times highlights have timed out'
      )
    end

    def self.over_highlight_size_limit
      @over_highlight_size_limit ||= Gitlab::Metrics.counter(
        :over_highlight_size_limit,
        'Count the times files have been over the highlight size limit'
      )
    end
  end
end
