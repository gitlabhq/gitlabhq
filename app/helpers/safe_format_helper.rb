# frozen_string_literal: true

module SafeFormatHelper
  # Returns a HTML-safe String.
  #
  # @param [String] format is escaped via `ERB::Util.html_escape_once`
  # @param [Array<Hash>] args are escaped via `ERB::Util.html_escape` if they are not marked as HTML-safe
  #
  # @example
  #   safe_format('See %{user_input}', user_input: '<b>bold</b>')
  #   # => "See &lt;b&gt;bold&lt;/b&gt"
  #
  #   safe_format('In &lt; hour & more')
  #   # => "In &lt; hour &amp; more"
  #
  # @example With +tag_pair+ support
  #   safe_format('Some %{open}bold%{close} text.', tag_pair(tag.strong, :open, :close))
  #   # => "Some <strong>bold</strong> text."
  #   safe_format('Some %{open}bold%{close} %{italicStart}text%{italicEnd}.',
  #     tag_pair(tag.strong, :open, :close),
  #     tag_pair(tag.i, :italicStart, :italicEnd))
  #   # => "Some <strong>bold</strong> <i>text</i>.
  def safe_format(format, *args)
    args = args.inject({}, &:merge)

    # Use `Kernel.format` to avoid conflicts with ViewComponent's `format`.
    Kernel.format(
      ERB::Util.html_escape_once(format),
      args.transform_values { |value| ERB::Util.html_escape(value) }
    ).html_safe
  end

  # Returns a Hash containing a pair of +open+ and +close+ tag parts extracted
  # from HTML-safe +tag+. The values are HTML-safe.
  #
  # Returns an empty Hash if +tag+ is not a valid paired tag (e.g. <p>foo</p>).
  # an empty Hash is returned.
  #
  # @param [String] html_tag is a HTML-safe output from tag helper
  # @param [Symbol,Object] open_name name of opening tag
  # @param [Symbol,Object] close_name name of closing tag
  # @raise [ArgumentError] if +tag+ is not HTML-safe
  #
  # @example
  #   tag_pair(tag.strong, :open, :close)
  #   # => { open: '<strong>', close: '</strong>' }
  #   tag_pair(link_to('', '/'), :open, :close)
  #   # => { open: '<a href="/">', close: '</a>' }
  def tag_pair(html_tag, open_name, close_name)
    raise ArgumentError, 'Argument `tag` must be `html_safe`!' unless html_tag.html_safe?
    return {} unless html_tag.start_with?('<')

    # end of opening tag: <p>foo</p>
    #                       ^
    open_index = html_tag.index('>')
    # start of closing tag: <p>foo</p>
    #                             ^^
    close_index = html_tag.rindex('</')

    return {} unless open_index && close_index

    {
      open_name => html_tag[0, open_index + 1],
      close_name => html_tag[close_index, html_tag.size]
    }
  end
end
