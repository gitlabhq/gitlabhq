# -*- ruby encoding: utf-8 -*-

# Based on the `ruby-net-ldap` gem's `Net::LDAP::DN`
#
# For our purposes, this class is used to normalize DNs in order to allow proper
# comparison.
#
# E.g. DNs should be compared case-insensitively (in basically all LDAP
# implementations or setups), therefore we downcase every DN.

##
# Objects of this class represent an LDAP DN ("Distinguished Name"). A DN
# ("Distinguished Name") is a unique identifier for an entry within an LDAP
# directory. It is made up of a number of other attributes strung together,
# to identify the entry in the tree.
#
# Each attribute that makes up a DN needs to have its value escaped so that
# the DN is valid. This class helps take care of that.
#
# A fully escaped DN needs to be unescaped when analysing its contents. This
# class also helps take care of that.
module Gitlab
  module LDAP
    class DN
      ##
      # Initialize a DN, escaping as required. Pass in attributes in name/value
      # pairs. If there is a left over argument, it will be appended to the dn
      # without escaping (useful for a base string).
      #
      # Most uses of this class will be to escape a DN, rather than to parse it,
      # so storing the dn as an escaped String and parsing parts as required
      # with a state machine seems sensible.
      def initialize(*args)
        buffer = StringIO.new

        args.each_index do |index|
          buffer << "=" if index % 2 == 1
          buffer << "," if index % 2 == 0 && index != 0

          arg = args[index].downcase

          if index < args.length - 1 || index % 2 == 1
            buffer << self.class.escape(arg)
          else
            buffer << arg
          end
        end

        @dn = buffer.string
      end

      ##
      # Parse a DN into key value pairs using ASN from
      # http://tools.ietf.org/html/rfc2253 section 3.
      def each_pair
        state = :key
        key = StringIO.new
        value = StringIO.new
        hex_buffer = ""

        @dn.each_char do |char|
          case state
          when :key then
            case char
            when 'a'..'z' then
              state = :key_normal
              key << char
            when '0'..'9' then
              state = :key_oid
              key << char
            when ' ' then state = :key
            else raise "DN badly formed"
            end
          when :key_normal then
            case char
            when '=' then state = :value
            when 'a'..'z', '0'..'9', '-', ' ' then key << char
            else raise "DN badly formed"
            end
          when :key_oid then
            case char
            when '=' then state = :value
            when '0'..'9', '.', ' ' then key << char
            else raise "DN badly formed"
            end
          when :value then
            case char
            when '\\' then state = :value_normal_escape
            when '"' then state = :value_quoted
            when ' ' then state = :value
            when '#' then
              state = :value_hexstring
              value << char
            when ',' then
              state = :key
              yield key.string.strip, value.string.rstrip
              key = StringIO.new
              value = StringIO.new;
            else
              state = :value_normal
              value << char
            end
          when :value_normal then
            case char
            when '\\' then state = :value_normal_escape
            when ',' then
              state = :key
              yield key.string.strip, value.string.rstrip
              key = StringIO.new
              value = StringIO.new;
            when '+' then raise(UnsupportedDnFormatError, "Multivalued RDNs are not supported")
            else value << char
            end
          when :value_normal_escape then
            case char
            when '0'..'9', 'a'..'f' then
              state = :value_normal_escape_hex
              hex_buffer = char
            when ' ' then state = :value_normal_escape_space; value << char
            else state = :value_normal; value << char
            end
          when :value_normal_escape_hex then
            case char
            when '0'..'9', 'a'..'f' then
              state = :value_normal
              value << "#{hex_buffer}#{char}".to_i(16).chr
            else raise "DN badly formed"
            end
          when :value_normal_escape_space then
            case char
            when '\\' then state = :value_normal_escape
            when ',' then
              state = :key
              yield key.string.strip, value.string # Don't strip trailing escaped space!
              key = StringIO.new
              value = StringIO.new;
            when '+' then raise(UnsupportedDnFormatError, "Multivalued RDNs are not supported")
            else value << char
            end
          when :value_quoted then
            case char
            when '\\' then state = :value_quoted_escape
            when '"' then state = :value_end
            else value << char
            end
          when :value_quoted_escape then
            case char
            when '0'..'9', 'a'..'f' then
              state = :value_quoted_escape_hex
              hex_buffer = char
            else
              state = :value_quoted;
              value << char
            end
          when :value_quoted_escape_hex then
            case char
            when '0'..'9', 'a'..'f' then
              state = :value_quoted
              value << "#{hex_buffer}#{char}".to_i(16).chr
            else raise "DN badly formed"
            end
          when :value_hexstring then
            case char
            when '0'..'9', 'a'..'f' then
              state = :value_hexstring_hex
              value << char
            when ' ' then state = :value_end
            when ',' then
              state = :key
              yield key.string.strip, value.string.rstrip
              key = StringIO.new
              value = StringIO.new;
            else raise "DN badly formed"
            end
          when :value_hexstring_hex then
            case char
            when '0'..'9', 'a'..'f' then
              state = :value_hexstring
              value << char
            else raise "DN badly formed"
            end
          when :value_end then
            case char
            when ' ' then state = :value_end
            when ',' then
              state = :key
              yield key.string.strip, value.string.rstrip
              key = StringIO.new
              value = StringIO.new;
            else raise "DN badly formed"
            end
          else raise "Fell out of state machine"
          end
        end

        # Last pair
        raise "DN badly formed" unless
          [:value, :value_normal, :value_hexstring, :value_end].include? state

        yield key.string.strip, value.string.rstrip
      end

      ##
      # Returns the DN as an array in the form expected by the constructor.
      def to_a
        a = []
        self.each_pair { |key, value| a << key << value } unless @dn.empty?
        a
      end

      ##
      # Return the DN as an escaped string.
      def to_s
        @dn
      end

      ##
      # Return the DN as an escaped and normalized string.
      def to_s_normalized
        self.class.new(*to_a).to_s
      end

      # https://tools.ietf.org/html/rfc4514 section 2.4 lists these exceptions
      # for DN values. All of the following must be escaped in any normal string
      # using a single backslash ('\') as escape. The space character is left
      # out here because in a "normalized" string, spaces should only be escaped
      # if necessary (i.e. leading or trailing space).
      NORMAL_ESCAPES = [',', '+', '"', '\\', '<', '>', ';', '=']

      # The following must be represented as escaped hex
      HEX_ESCAPES = {
        "\n" => '\0a',
        "\r" => '\0d'
      }

      # Compiled character class regexp using the keys from the above hash, and
      # checking for a space or # at the start, or space at the end, of the
      # string.
      ESCAPE_RE = Regexp.new("(^ |^#| $|[" +
                             NORMAL_ESCAPES.map { |e| Regexp.escape(e) }.join +
                             "])")

      HEX_ESCAPE_RE = Regexp.new("([" +
                             HEX_ESCAPES.keys.map { |e| Regexp.escape(e) }.join +
                             "])")

      ##
      # Escape a string for use in a DN value
      def self.escape(string)
        escaped = string.gsub(ESCAPE_RE) { |char| "\\" + char }
        escaped.gsub(HEX_ESCAPE_RE) { |char| HEX_ESCAPES[char] }
      end

      ##
      # Proxy all other requests to the string object, because a DN is mainly
      # used within the library as a string
      def method_missing(method, *args, &block)
        @dn.send(method, *args, &block)
      end
    end
  end
end
