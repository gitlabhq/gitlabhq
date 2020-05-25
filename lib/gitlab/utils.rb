# frozen_string_literal: true

module Gitlab
  module Utils
    extend self
    PathTraversalAttackError ||= Class.new(StandardError)

    # Ensure that the relative path will not traverse outside the base directory
    # We url decode the path to avoid passing invalid paths forward in url encoded format.
    # We are ok to pass some double encoded paths to File.open since they won't resolve.
    # Also see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24223#note_284122580
    # It also checks for ALT_SEPARATOR aka '\' (forward slash)
    def check_path_traversal!(path, allowed_absolute: false)
      path = CGI.unescape(path)

      if path.start_with?("..#{File::SEPARATOR}", "..#{File::ALT_SEPARATOR}") ||
          path.include?("#{File::SEPARATOR}..#{File::SEPARATOR}") ||
          path.end_with?("#{File::SEPARATOR}..") ||
          (!allowed_absolute && Pathname.new(path).absolute?)

        raise PathTraversalAttackError.new('Invalid path')
      end

      path
    end

    def force_utf8(str)
      str.dup.force_encoding(Encoding::UTF_8)
    end

    def ensure_utf8_size(str, bytes:)
      raise ArgumentError, 'Empty string provided!' if str.empty?
      raise ArgumentError, 'Negative string size provided!' if bytes.negative?

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
      return str.downcase
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

    def string_to_ip_object(str)
      return unless str

      IPAddr.new(str)
    rescue IPAddr::InvalidAddressError
    end

    # Converts a string to an Addressable::URI object.
    # If the string is not a valid URI, it returns nil.
    # Param uri_string should be a String object.
    # This method returns an Addressable::URI object or nil.
    def parse_url(uri_string)
      Addressable::URI.parse(uri_string)
    rescue Addressable::URI::InvalidURIError, TypeError
    end
  end
end
