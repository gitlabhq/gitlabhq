# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class NormalizeLdapExternUids < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class Identity < ActiveRecord::Base
    self.table_name = 'identities'
  end

  # Copied this class to make this migration resilient to future code changes.
  # And if the normalize behavior is changed in the future, it must be
  # accompanied by another migration.
  module Gitlab
    module LDAP
      MalformedDnError = Class.new(StandardError)
      UnsupportedDnFormatError = Class.new(StandardError)

      class DN
        def self.normalize_value(given_value)
          dummy_dn = "placeholder=#{given_value}"
          normalized_dn = new(*dummy_dn).to_normalized_s
          normalized_dn.sub(/\Aplaceholder=/, '')
        end

        ##
        # Initialize a DN, escaping as required. Pass in attributes in name/value
        # pairs. If there is a left over argument, it will be appended to the dn
        # without escaping (useful for a base string).
        #
        # Most uses of this class will be to escape a DN, rather than to parse it,
        # so storing the dn as an escaped String and parsing parts as required
        # with a state machine seems sensible.
        def initialize(*args)
          @dn = if args.length > 1
                  initialize_array(args)
                else
                  initialize_string(args[0])
                end
        end

        def initialize_array(args)
          buffer = StringIO.new

          args.each_with_index do |arg, index|
            if index.even? # key
              buffer << "," if index > 0
              buffer << arg
            else # value
              buffer << "="
              buffer << self.class.escape(arg)
            end
          end

          buffer.string
        end

        def initialize_string(arg)
          arg.to_s
        end

        ##
        # Parse a DN into key value pairs using ASN from
        # http://tools.ietf.org/html/rfc2253 section 3.
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def each_pair
          state = :key
          key = StringIO.new
          value = StringIO.new
          hex_buffer = ""

          @dn.each_char.with_index do |char, dn_index|
            case state
            when :key then
              case char
              when 'a'..'z', 'A'..'Z' then
                state = :key_normal
                key << char
              when '0'..'9' then
                state = :key_oid
                key << char
              when ' ' then state = :key
              else raise(MalformedDnError, "Unrecognized first character of an RDN attribute type name \"#{char}\"")
              end
            when :key_normal then
              case char
              when '=' then state = :value
              when 'a'..'z', 'A'..'Z', '0'..'9', '-', ' ' then key << char
              else raise(MalformedDnError, "Unrecognized RDN attribute type name character \"#{char}\"")
              end
            when :key_oid then
              case char
              when '=' then state = :value
              when '0'..'9', '.', ' ' then key << char
              else raise(MalformedDnError, "Unrecognized RDN OID attribute type name character \"#{char}\"")
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
                yield key.string.strip, rstrip_except_escaped(value.string, dn_index)
                key = StringIO.new
                value = StringIO.new
              else
                state = :value_normal
                value << char
              end
            when :value_normal then
              case char
              when '\\' then state = :value_normal_escape
              when ',' then
                state = :key
                yield key.string.strip, rstrip_except_escaped(value.string, dn_index)
                key = StringIO.new
                value = StringIO.new
              when '+' then raise(UnsupportedDnFormatError, "Multivalued RDNs are not supported")
              else value << char
              end
            when :value_normal_escape then
              case char
              when '0'..'9', 'a'..'f', 'A'..'F' then
                state = :value_normal_escape_hex
                hex_buffer = char
              else
                state = :value_normal
                value << char
              end
            when :value_normal_escape_hex then
              case char
              when '0'..'9', 'a'..'f', 'A'..'F' then
                state = :value_normal
                value << "#{hex_buffer}#{char}".to_i(16).chr
              else raise(MalformedDnError, "Invalid escaped hex code \"\\#{hex_buffer}#{char}\"")
              end
            when :value_quoted then
              case char
              when '\\' then state = :value_quoted_escape
              when '"' then state = :value_end
              else value << char
              end
            when :value_quoted_escape then
              case char
              when '0'..'9', 'a'..'f', 'A'..'F' then
                state = :value_quoted_escape_hex
                hex_buffer = char
              else
                state = :value_quoted
                value << char
              end
            when :value_quoted_escape_hex then
              case char
              when '0'..'9', 'a'..'f', 'A'..'F' then
                state = :value_quoted
                value << "#{hex_buffer}#{char}".to_i(16).chr
              else raise(MalformedDnError, "Expected the second character of a hex pair inside a double quoted value, but got \"#{char}\"")
              end
            when :value_hexstring then
              case char
              when '0'..'9', 'a'..'f', 'A'..'F' then
                state = :value_hexstring_hex
                value << char
              when ' ' then state = :value_end
              when ',' then
                state = :key
                yield key.string.strip, rstrip_except_escaped(value.string, dn_index)
                key = StringIO.new
                value = StringIO.new
              else raise(MalformedDnError, "Expected the first character of a hex pair, but got \"#{char}\"")
              end
            when :value_hexstring_hex then
              case char
              when '0'..'9', 'a'..'f', 'A'..'F' then
                state = :value_hexstring
                value << char
              else raise(MalformedDnError, "Expected the second character of a hex pair, but got \"#{char}\"")
              end
            when :value_end then
              case char
              when ' ' then state = :value_end
              when ',' then
                state = :key
                yield key.string.strip, rstrip_except_escaped(value.string, dn_index)
                key = StringIO.new
                value = StringIO.new
              else raise(MalformedDnError, "Expected the end of an attribute value, but got \"#{char}\"")
              end
            else raise "Fell out of state machine"
            end
          end

          # Last pair
          raise(MalformedDnError, 'DN string ended unexpectedly') unless
            [:value, :value_normal, :value_hexstring, :value_end].include? state

          yield key.string.strip, rstrip_except_escaped(value.string, @dn.length)
        end

        def rstrip_except_escaped(str, dn_index)
          str_ends_with_whitespace = str.match(/\s\z/)

          if str_ends_with_whitespace
            dn_part_ends_with_escaped_whitespace = @dn[0, dn_index].match(/\\(\s+)\z/)

            if dn_part_ends_with_escaped_whitespace
              dn_part_rwhitespace = dn_part_ends_with_escaped_whitespace[1]
              num_chars_to_remove = dn_part_rwhitespace.length - 1
              str = str[0, str.length - num_chars_to_remove]
            else
              str.rstrip!
            end
          end

          str
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
        def to_normalized_s
          self.class.new(*to_a).to_s.downcase
        end

        # https://tools.ietf.org/html/rfc4514 section 2.4 lists these exceptions
        # for DN values. All of the following must be escaped in any normal string
        # using a single backslash ('\') as escape. The space character is left
        # out here because in a "normalized" string, spaces should only be escaped
        # if necessary (i.e. leading or trailing space).
        NORMAL_ESCAPES = [',', '+', '"', '\\', '<', '>', ';', '='].freeze

        # The following must be represented as escaped hex
        HEX_ESCAPES = {
          "\n" => '\0a',
          "\r" => '\0d'
        }.freeze

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
        # rubocop:disable GitlabSecurity/PublicSend
        def method_missing(method, *args, &block)
          @dn.send(method, *args, &block)
        end
      end
    end
  end

  def up
    ldap_identities = Identity.where("provider like 'ldap%'")
    ldap_identities.find_each do |identity|
      begin
        identity.extern_uid = Gitlab::LDAP::DN.new(identity.extern_uid).to_normalized_s
        unless identity.save
          say "Unable to normalize \"#{identity.extern_uid}\". Skipping."
        end
      rescue Gitlab::LDAP::MalformedDnError, Gitlab::LDAP::UnsupportedDnFormatError => e
        say "Unable to normalize \"#{identity.extern_uid}\" due to \"#{e.message}\". Skipping."
      end
    end
  end

  def down
  end
end
