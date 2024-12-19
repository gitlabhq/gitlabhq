# frozen_string_literal: true

require "addressable/uri"
require "active_support/all"
require "action_view"

module Gitlab
  module Utils
    extend self
    DoubleEncodingError = Class.new(StandardError)
    ConcurrentRubyThreadIsUsedError = Class.new(StandardError)

    def allowlisted?(absolute_path, allowlist)
      allowlist.any? do |allowed_path|
        absolute_path.start_with?(allowed_path)
      end
    end

    def decode_path(encoded_path)
      decoded = CGI.unescape(encoded_path)
      if decoded != CGI.unescape(decoded) # rubocop:disable Style/IfUnlessModifier
        raise DoubleEncodingError, "path #{encoded_path} is not allowed"
      end

      decoded
    end

    def force_utf8(str)
      str.dup.force_encoding(Encoding::UTF_8)
    end

    def ensure_utf8_size(str, bytes:)
      raise ArgumentError, 'Empty string provided!' if str.empty?
      raise ArgumentError, 'Negative string size provided!' if bytes < 0

      truncated = str.each_char.each_with_object(+'') do |char, object|
        if object.bytesize + char.bytesize > bytes # rubocop:disable Style/GuardClause
          break object
        else
          object.concat(char)
        end
      end

      truncated + ('0' * (bytes - truncated.bytesize))
    end

    # Append path to host, making sure there's one single / in between
    def append_path(host, path)
      "#{host.to_s.sub(%r{\/+$}, '')}/#{remove_leading_slashes(path)}" # rubocop:disable Style/RedundantRegexpEscape
    end

    def remove_leading_slashes(str)
      str.to_s.sub(%r{^/+}, '')
    end

    # A slugified version of the string, suitable for inclusion in URLs and
    # domain names. Rules:
    #
    #   * Lowercased
    #   * Anything not matching [a-z0-9-] is replaced with a -
    #   * Conditionally allows dots [a-z0-9-.]
    #   * Maximum length is 63 bytes
    #   * First/Last Character is not a hyphen or a dot
    def slugify(str, allow_dots: false)
      pattern = allow_dots ? /[^a-z0-9.]/ : /[^a-z0-9]/
      str.downcase
        .gsub(pattern, '-')[0..62]
        .gsub(/(\A[-.]+|[-.]+\z)/, '')
    end

    # Converts newlines into HTML line break elements
    def nlbr(str)
      ActionView::Base.full_sanitizer.sanitize(+str, tags: []).gsub(/\r?\n/, '<br>').html_safe
    end

    def remove_line_breaks(str)
      str.gsub(/\r?\n/, '')
    end

    def to_boolean(value, default: nil)
      value = value.to_s if [0, 1].include?(value)

      return value if [true, false].include?(value)
      return true if value =~ /^(true|t|yes|y|1|on)$/i
      return false if value =~ /^(false|f|no|n|0|off)$/i

      default
    end

    def boolean_to_yes_no(bool)
      if bool
        'Yes'
      else
        'No'
      end
    end

    # Behaves like `which` on Linux machines: given PATH, try to resolve the given
    # executable name to an absolute path, or return nil.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(filename)
      ENV['PATH']&.split(File::PATH_SEPARATOR)&.each do |path|
        full_path = File.join(path, filename)
        return full_path if File.executable?(full_path)
      end

      nil
    end

    def try_megabytes_to_bytes(size)
      Integer(size).megabytes
    rescue ArgumentError
      size
    end

    def bytes_to_megabytes(bytes)
      bytes.to_f / Numeric::MEGABYTE
    end

    def ms_to_round_sec(ms)
      (ms.to_f / 1000).round(6)
    end

    # Used in EE
    # Accepts either an Array or a String and returns an array
    def ensure_array_from_string(string_or_array)
      return string_or_array if string_or_array.is_a?(Array)

      string_or_array.split(',').map(&:strip)
    end

    def deep_indifferent_access(data)
      case data
      when Array
        data.map { |item| deep_indifferent_access(item) }
      when Hash
        data.with_indifferent_access
      else
        data
      end
    end

    def deep_symbolized_access(data)
      case data
      when Array
        data.map { |item| deep_symbolized_access(item) }
      when Hash
        data.deep_symbolize_keys
      else
        data
      end
    end

    def string_to_ip_object(str)
      return unless str

      IPAddr.new(str)
    rescue IPAddr::InvalidAddressError
    end

    # A safe alternative to String#downcase!
    #
    # This will make copies of frozen strings but downcase unfrozen
    # strings in place, reducing allocations.
    def safe_downcase!(str)
      if str.frozen?
        str.downcase
      else
        str.downcase! || str
      end
    end

    # Converts a string to an Addressable::URI object.
    # If the string is not a valid URI, it returns nil.
    # Param uri_string should be a String object.
    # This method returns an Addressable::URI object or nil.
    def parse_url(uri_string)
      Addressable::URI.parse(uri_string)
    rescue Addressable::URI::InvalidURIError, TypeError
    end

    def add_url_parameters(url, params)
      uri = parse_url(url.to_s)
      uri.query_values = uri.query_values.to_h.merge(params.to_h.stringify_keys)
      uri.query_values = nil if uri.query_values.empty?
      uri.to_s
    end

    def removes_sensitive_data_from_url(uri_string)
      uri = parse_url(uri_string)

      return unless uri
      return uri_string unless uri.fragment

      stripped_params = CGI.parse(uri.fragment)
      if stripped_params['access_token']
        stripped_params['access_token'] = 'filtered'
        filtered_query = Addressable::URI.new
        filtered_query.query_values = stripped_params

        uri.fragment = filtered_query.query
      end

      uri.to_s
    end

    # Invert a hash, collecting all keys that map to a given value in an array.
    #
    # Unlike `Hash#invert`, where the last encountered pair wins, and which has the
    # type `Hash[k, v] => Hash[v, k]`, `multiple_key_invert` does not lose any
    # information, has the type `Hash[k, v] => Hash[v, Array[k]]`, and the original
    # hash can always be reconstructed.
    #
    # example:
    #
    #   multiple_key_invert({ a: 1, b: 2, c: 1 })
    #   # => { 1 => [:a, :c], 2 => [:b] }
    #
    def multiple_key_invert(hash)
      hash.flat_map { |k, v| Array.wrap(v).zip([k].cycle) }
        .group_by(&:first)
        .transform_values { |kvs| kvs.map(&:last) }
    end

    # This sort is stable (see https://en.wikipedia.org/wiki/Sorting_algorithm#Stability)
    # contrary to the bare Ruby sort_by method. Using just sort_by leads to
    # instability across different platforms (e.g., x86_64-linux and x86_64-darwin18)
    # which in turn leads to different sorting results for the equal elements across
    # these platforms.
    # This method uses a list item's original index position to break ties.
    def stable_sort_by(list)
      list.sort_by.with_index { |x, idx| [yield(x), idx] }
    end

    # Check for valid brackets (`[` and `]`) in a string using this aspects:
    # * open brackets count == closed brackets count
    # * (optionally) reject nested brackets via `allow_nested: false`
    # * open / close brackets coherence, eg. ][[] -> invalid
    def valid_brackets?(string = '', allow_nested: true)
      # remove everything except brackets
      brackets = string.remove(/[^\[\]]/)

      return true if brackets.empty?
      # balanced counts check
      return false if brackets.size.odd?

      unless allow_nested
        # nested brackets check
        return false if brackets.include?('[[') || brackets.include?(']]') # rubocop:disable Style/SoleNestedConditional
      end

      # open / close brackets coherence check
      untrimmed = brackets
      loop do
        trimmed = untrimmed.gsub('[]', '')
        return true if trimmed.empty?
        return false if trimmed == untrimmed

        untrimmed = trimmed
      end
    end

    # Use this method to set the `restrict_within_concurrent_ruby` to `true` for the block.
    # `raise_if_concurrent_ruby!` will use this flag to raise an error if it's set to `true`.
    def restrict_within_concurrent_ruby
      previous = Thread.current[:restrict_within_concurrent_ruby]
      Thread.current[:restrict_within_concurrent_ruby] = true

      yield
    ensure
      Thread.current[:restrict_within_concurrent_ruby] = previous
    end

    # Use this method to disable the `restrict_within_concurrent_ruby` for the block.
    # It is mainly used to prevent infinite loop when `ConcurrentRubyThreadIsUsedError` is rescued and sent to Sentry.
    # More info: https://gitlab.com/gitlab-org/gitlab/-/issues/432145#note_1671305713
    def allow_within_concurrent_ruby
      previous = Thread.current[:restrict_within_concurrent_ruby]
      Thread.current[:restrict_within_concurrent_ruby] = false

      yield
    ensure
      Thread.current[:restrict_within_concurrent_ruby] = previous
    end

    # Running external methods can allocate I/O bound resources (like PostgreSQL connection or Gitaly)
    # This is forbidden when running within a concurrent Ruby thread, for example `async` HTTP requests
    # provided by the `gitlab-http` gem.
    def raise_if_concurrent_ruby!(what)
      return unless Thread.current[:restrict_within_concurrent_ruby]

      raise ConcurrentRubyThreadIsUsedError, "Cannot run '#{what}' if running from `Concurrent::Promise`."
    end

    # Returns a valid Rails log_level, given a user input and an optional fallback
    #
    # `config.log_level=` does NOT accept integers, but Ruby Loggers do.
    #
    # @return [Symbol, nil]
    def to_rails_log_level(input, fallback = nil)
      case input.to_s.downcase
      when 'debug',   '0' then :debug
      when 'info',    '1' then :info
      when 'warn',    '2' then :warn
      when 'error',   '3' then :error
      when 'fatal',   '4' then :fatal
      when 'unknown', '5' then :unknown
      else
        return :info unless fallback

        # Normalize the fallback value, just in case
        to_rails_log_level(fallback)
      end
    end

    # Use this method to recursively sort a hash on its keys
    def deep_sort_hash(hash)
      hash.keys.sort.each_with_object({}) do |key, sorted_hash|
        value = hash[key]
        sorted_hash[key] = value.is_a?(Hash) ? deep_sort_hash(value) : value
      end
    end
  end
end
