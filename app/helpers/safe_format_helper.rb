# frozen_string_literal: true

module SafeFormatHelper
  # Returns a HTML-safe string where +format+ and +args+ are escaped via
  # `html_escape` if they are not marked as HTML-safe.
  #
  # Argument +format+ must not be marked as HTML-safe via `.html_safe`.
  #
  # Example:
  #   safe_format('Some %{open}bold%{close} text.', open: '<strong>'.html_safe, close: '</strong>'.html_safe)
  #   # => 'Some <strong>bold</strong>'
  #   safe_format('See %{user_input}', user_input: '<b>bold</b>')
  #   # => 'See &lt;b&gt;bold&lt;/b&gt;
  #
  def safe_format(format, **args)
    raise ArgumentError, 'Argument `format` must not be marked as html_safe!' if format.html_safe?

    format(
      html_escape(format),
      args.transform_values { |value| html_escape(value) }
    ).html_safe
  end
end
