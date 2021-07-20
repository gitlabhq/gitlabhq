# frozen_string_literal: true

module Gitlab
  module Utils
    extend self
    PathTraversalAttackError ||= Class.new(StandardError)

    # Ensure that the relative path will not traverse outside the base directory
    # We url decode the path to avoid passing invalid paths forward in url encoded format.
    # Also see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24223#note_284122580
    # It also checks for ALT_SEPARATOR aka '\' (forward slash)
    def check_path_traversal!(path)
      return unless path.is_a?(String)

      path = decode_path(path)
      path_regex = /(\A(\.{1,2})\z|\A\.\.[\/\\]|[\/\\]\.\.\z|[\/\\]\.\.[\/\\]|\n)/

      if path.match?(path_regex)
        raise PathTraversalAttackError, 'Invalid path'
      end

      path
    end

    def allowlisted?(absolute_path, allowlist)
      path = absolute_path.downcase

      allowlist.map(&:downcase).any? do |allowed_path|
        path.start_with?(allowed_path)
      end
    end

    def check_allowed_absolute_path!(path, allowlist)
      return unless Pathname.new(path).absolute?
      return if allowlisted?(path, allowlist)

      raise StandardError, "path #{path} is not allowed"
    end

    def decode_path(encoded_path)
      decoded = CGI.unescape(encoded_path)
      if decoded != CGI.unescape(decoded)
        raise StandardError, "path #{encoded_path} is not allowed"
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
        if object.bytesize + char.bytesize > bytes
          break object
        else
          object.concat(char)
        end
      end

      truncated + ('0' * (bytes - truncated.bytesize))
    end

    # Append path to host, making sure there's one single / in between
    def append_path(host, path)
      "#{host.to_s.sub(%r{\/+$}, '')}/#{path.to_s.sub(%r{^\/+}, '')}"
    end

    # A slugified version of the string, suitable for inclusion in URLs and
    # domain names. Rules:
    #
    #   * Lowercased
    #   * Anything not matching [a-z0-9-] is replaced with a -
    #   * Maximum length is 63 bytes
    #   * First/Last Character is not a hyphen
    def slugify(str)
      str.downcase
        .gsub(/[^a-z0-9]/, '-')[0..62]
        .gsub(/(\A-+|-+\z)/, '')
    end

    # Wraps ActiveSupport's Array#to_sentence to convert the given array to a
    # comma-separated sentence joined with localized 'or' Strings instead of 'and'.
    def to_exclusive_sentence(array)
      array.to_sentence(two_words_connector: _(' or '), last_word_connector: _(', or '))
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

    def random_string
      Random.rand(Float::MAX.to_i).to_s(36)
    end

    # See: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd, env = ENV)
      exts = env['PATHEXT'] ? env['PATHEXT'].split(';') : ['']

      env['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
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
      if data.is_a?(Array)
        data.map(&method(:deep_indifferent_access))
      elsif data.is_a?(Hash)
        data.with_indifferent_access
      else
        data
      end
    end

    def deep_symbolized_access(data)
      if data.is_a?(Array)
        data.map(&method(:deep_symbolized_access))
      elsif data.is_a?(Hash)
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
        return false if brackets.include?('[[') || brackets.include?(']]')
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
  end
end
