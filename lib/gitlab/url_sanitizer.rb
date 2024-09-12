# frozen_string_literal: true

module Gitlab
  class UrlSanitizer
    include Gitlab::Utils::StrongMemoize

    ALLOWED_SCHEMES = %w[http https ssh git].freeze
    ALLOWED_WEB_SCHEMES = %w[http https].freeze
    SCHEMIFIED_SCHEME = 'glschemelessuri'
    SCHEMIFY_PLACEHOLDER = "#{SCHEMIFIED_SCHEME}://".freeze
    # SCP style URLs have a format of [userinfo]@[host]:[path] with them not containing
    # port arguments as that is passed along with a -P argument
    SCP_REGEX = %r{
      #{URI::REGEXP::PATTERN::USERINFO}@#{URI::REGEXP::PATTERN::HOST}:
      (?!\b\d+\b) # use word boundaries to ensure no standalone digits after the colon
    }x
    # URI::DEFAULT_PARSER.make_regexp will only match URLs with schemes or
    # relative URLs. This section will match schemeless URIs with userinfo
    # e.g. user:pass@gitlab.com but will not match scp-style URIs e.g.
    # user@server:path/to/file)
    #
    # The userinfo part is very loose compared to URI's implementation so we
    # also match non-escaped userinfo e.g foo:b?r@gitlab.com which should be
    # encoded as foo:b%3Fr@gitlab.com
    URI_REGEXP = %r{
    (?:
       #{URI::DEFAULT_PARSER.make_regexp(ALLOWED_SCHEMES)}
     |
       (?# negative lookahead before the schemeless matcher ensures this isn't an SCP-style URL)
       (?!#{SCP_REGEX})
       (?:(?:(?!@)[%#{URI::REGEXP::PATTERN::UNRESERVED}#{URI::REGEXP::PATTERN::RESERVED}])+(?:@))
       #{URI::REGEXP::PATTERN::HOSTPORT}
    )
    }x
    # This expression is derived from `URI::REGEXP::PATTERN::USERINFO` but with the
    # addition of `{` and `}` in the list of allowed characters to account for the
    # possibility of the userinfo portion of a URL containing masked segments.
    # e.g.
    # http://myuser:{masked_password}@{masked_domain}.com/{masked_hook}
    MASKED_USERINFO_REGEX = %r{(?:[\\-_.!~*'()a-zA-Z\d;:&=+$,{}]|%[a-fA-F\d]{2})*}

    def self.sanitize(content)
      content.gsub(URI_REGEXP) do |url|
        new(url).masked_url
      rescue Addressable::URI::InvalidURIError
        ''
      end
    end

    def self.valid?(url, allowed_schemes: ALLOWED_SCHEMES)
      return false unless url.present?
      return false unless url.is_a?(String)

      uri = Addressable::URI.parse(url.strip)

      allowed_schemes.include?(uri.scheme)
    rescue Addressable::URI::InvalidURIError
      false
    end

    def self.valid_web?(url)
      valid?(url, allowed_schemes: ALLOWED_WEB_SCHEMES)
    end

    # The url associated with records like `WebHookLog` may contain masked
    # portions represented by paired curly brackets in the URL. As this
    # prohibits straightforward parsing of the URL, we can use a variation of
    # the existing USERINFO regex for these cases.
    def self.sanitize_masked_url(url)
      url.gsub(%r{//#{MASKED_USERINFO_REGEX}@}o, '//*****:*****@')
    end

    def initialize(url, credentials: nil)
      %i[user password].each do |symbol|
        credentials[symbol] = credentials[symbol].presence if credentials&.key?(symbol)
      end

      @credentials = credentials
      @url = parse_url(url)
    end

    def credentials
      @credentials ||= { user: @url.user.presence, password: @url.password.presence }
    end

    def user
      credentials[:user]
    end

    def sanitized_url
      safe_url = @url.dup
      safe_url.password = nil
      safe_url.user = nil
      reverse_schemify(safe_url.to_s)
    end
    strong_memoize_attr :sanitized_url

    def masked_url
      url = @url.dup
      url.password = "*****" if url.password.present?
      url.user = "*****" if url.user.present?
      reverse_schemify(url.to_s)
    end
    strong_memoize_attr :masked_url

    def full_url
      return reverse_schemify(@url.to_s) unless valid_credentials?

      url = @url.dup
      url.password = encode_percent(credentials[:password]) if credentials[:password].present?
      url.user = encode_percent(credentials[:user]) if credentials[:user].present?
      reverse_schemify(url.to_s)
    end
    strong_memoize_attr :full_url

    private

    def parse_url(url)
      url = schemify(url.to_s.strip)
      match = url.match(%r{\A(?:(?:#{SCHEMIFIED_SCHEME}|git|ssh|http(?:s?)):)?//(?:(.+)(?:@))?(.+)}o)
      raw_credentials = match[1] if match

      if raw_credentials.present?
        url.sub!("#{raw_credentials}@", '')

        user, _, password = raw_credentials.partition(':')

        @credentials ||= {}
        @credentials[:user] = user.presence if @credentials[:user].blank?
        @credentials[:password] = password.presence if @credentials[:password].blank?
      end

      url = Addressable::URI.parse(url)
      url.password = password if password.present?
      url.user = user if user.present?
      url
    end

    def schemify(url)
      # Prepend the placeholder scheme unless the URL has a scheme or is relative
      url.prepend(SCHEMIFY_PLACEHOLDER) unless url.starts_with?(%r{(?:#{URI::REGEXP::PATTERN::SCHEME}:)?//}o)
      url
    end

    def reverse_schemify(url)
      url.slice!(SCHEMIFY_PLACEHOLDER) if url.starts_with?(SCHEMIFY_PLACEHOLDER)
      url
    end

    def valid_credentials?
      credentials.is_a?(Hash) && credentials.values.any?
    end

    def encode_percent(string)
      # CGI.escape converts spaces to +, but this doesn't work for git clone
      CGI.escape(string).gsub('+', '%20')
    end
  end
end
