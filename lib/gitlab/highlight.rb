# frozen_string_literal: true

module Gitlab
  class Highlight
    include Gitlab::Loggable

    def self.highlight(
      blob_name, blob_content, language: nil, plain: false, context: {}, used_on: :blob,
      suppress_line_ids: nil)
      new(blob_name, blob_content, language: language)
        .highlight(blob_content, continue: false, plain: plain, context: context, used_on: used_on,
          suppress_line_ids: suppress_line_ids)
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

    def highlight(text, continue: false, plain: false, context: {}, used_on: :blob, suppress_line_ids: nil)
      @context = context

      plain ||= self.class.too_large?(text.length)

      highlighted_text = highlight_text(text, continue: continue, plain: plain, used_on: used_on,
        suppress_line_ids: suppress_line_ids)
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

    def highlight_text(text, continue: true, plain: false, used_on: :blob, suppress_line_ids: nil)
      @gitlab_highlight_usage_counter.increment(used_on: used_on)
      # Line IDs are suppressed for diffs by default; callers may force either way.
      suppress_line_ids = used_on == :diff if suppress_line_ids.nil?

      if plain
        highlight_plain(text, suppress_line_ids:)
      else
        highlight_rich(text, continue:, suppress_line_ids:)
      end
    end

    def highlight_plain(text, suppress_line_ids: false)
      @formatter.format(Rouge::Lexers::PlainText.lex(text), **context, suppress_line_ids:).html_safe
    end

    def highlight_rich(text, continue: true, suppress_line_ids: false)
      tag = lexer.tag
      tokens = lexer.lex(text, continue: continue)
      Gitlab::RenderTimeout.timeout { @formatter.format(tokens, **context, tag:, suppress_line_ids:).html_safe }
    rescue Timeout::Error => e
      ErrorTracking.log_exception(
        e,
        message: 'Syntax highlighting timeout.',
        lexer_tag: tag,
        text_length: text.length
      )
      highlight_plain_fallback(text, reason: 'timeout', suppress_line_ids: suppress_line_ids)
    rescue StandardError
      highlight_plain_fallback(text, reason: 'error', suppress_line_ids: suppress_line_ids)
    end

    def highlight_plain_fallback(text, reason:, suppress_line_ids: false)
      start = Gitlab::Metrics::System.monotonic_time
      result = highlight_plain(text, suppress_line_ids:)
      duration_s = Gitlab::Metrics::System.monotonic_time - start

      Gitlab::AppJsonLogger.info(
        build_structured_payload_labkit(
          message: 'Fallback to plain highlighting',
          plain_fallback_duration_s: duration_s,
          fallback_reason: reason,
          text_length: text.length,
          lexer_tag: @lexer&.tag,
          sidekiq: Gitlab::Runtime.sidekiq?
        )
      )

      result
    end

    def link_dependencies(text, highlighted_text, used_on: :blob)
      Gitlab::DependencyLinker.link(blob_name, text, highlighted_text, used_on: used_on)
    end
  end
end
