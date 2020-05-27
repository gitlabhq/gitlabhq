# frozen_string_literal: true

module Gitlab
  class UrlSanitizer
    ALLOWED_SCHEMES = %w[http https ssh git].freeze
    ALLOWED_WEB_SCHEMES = %w[http https].freeze

    def self.sanitize(content)
      regexp = URI::DEFAULT_PARSER.make_regexp(ALLOWED_SCHEMES)

      content.gsub(regexp) { |url| new(url).masked_url }
    rescue Addressable::URI::InvalidURIError
      content.gsub(regexp, '')
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

    def initialize(url, credentials: nil)
      %i[user password].each do |symbol|
        credentials[symbol] = credentials[symbol].presence if credentials&.key?(symbol)
      end

      @credentials = credentials
      @url = parse_url(url)
    end

    def sanitized_url
      @sanitized_url ||= safe_url.to_s
    end

    def masked_url
      url = @url.dup
      url.password = "*****" if url.password.present?
      url.user = "*****" if url.user.present?
      url.to_s
    end

    def credentials
      @credentials ||= { user: @url.user.presence, password: @url.password.presence }
    end

    def user
      credentials[:user]
    end

    def full_url
      @full_url ||= generate_full_url.to_s
    end

    private

    def parse_url(url)
      url             = url.to_s.strip
      match           = url.match(%r{\A(?:git|ssh|http(?:s?))\://(?:(.+)(?:@))?(.+)})
      raw_credentials = match[1] if match

      if raw_credentials.present?
        url.sub!("#{raw_credentials}@", '')

        user, _, password = raw_credentials.partition(':')
        @credentials ||= { user: user.presence, password: password.presence }
      end

      url = Addressable::URI.parse(url)
      url.password = password if password.present?
      url.user = user if user.present?
      url
    end

    def generate_full_url
      return @url unless valid_credentials?

      @url.dup.tap do |generated|
        generated.password = encode_percent(credentials[:password]) if credentials[:password].present?
        generated.user = encode_percent(credentials[:user]) if credentials[:user].present?
      end
    end

    def safe_url
      safe_url = @url.dup
      safe_url.password = nil
      safe_url.user = nil
      safe_url
    end

    def valid_credentials?
      credentials && credentials.is_a?(Hash) && credentials.any?
    end

    def encode_percent(string)
      # CGI.escape converts spaces to +, but this doesn't work for git clone
      CGI.escape(string).gsub('+', '%20')
    end
  end
end
