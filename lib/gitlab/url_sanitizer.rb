module Gitlab
  class UrlSanitizer
    ALLOWED_SCHEMES = %w[http https ssh git].freeze

    def self.sanitize(content)
      regexp = URI::Parser.new.make_regexp(ALLOWED_SCHEMES)

      content.gsub(regexp) { |url| new(url).masked_url }
    rescue Addressable::URI::InvalidURIError
      content.gsub(regexp, '')
    end

    def self.valid?(url)
      return false unless url.present?

      uri = Addressable::URI.parse(url.strip)

      ALLOWED_SCHEMES.include?(uri.scheme)
    rescue Addressable::URI::InvalidURIError
      false
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

        user, password = raw_credentials.split(':')
        @credentials ||= { user: user.presence, password: password.presence }
      end

      url = Addressable::URI.parse(url)
      url.password = password if password.present?
      url.user = user if user.present?
      url
    end

    def generate_full_url
      return @url unless valid_credentials?

      @full_url = @url.dup

      @full_url.password = credentials[:password] if credentials[:password].present?
      @full_url.user = credentials[:user] if credentials[:user].present?

      @full_url
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
  end
end
