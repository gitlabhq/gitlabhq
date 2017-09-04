module Gitlab
  class UrlSanitizer
    def self.sanitize(content)
      regexp = URI::Parser.new.make_regexp(%w(http https ssh git))

      content.gsub(regexp) { |url| new(url).masked_url }
    rescue Addressable::URI::InvalidURIError
      content.gsub(regexp, '')
    end

    def self.valid?(url)
      return false unless url.present?

      Addressable::URI.parse(url.strip)

      true
    rescue Addressable::URI::InvalidURIError
      false
    end

    def initialize(url, credentials: nil)
      @credentials = credentials
      @url = parse_url(url)
    end

    def sanitized_url
      @sanitized_url ||= safe_url.to_s
    end

    def masked_url
      url = @url.dup
      url.password = "*****" if url.password
      url.user = "*****" if url.user
      url.to_s
    end

    def credentials
      @credentials ||= { user: @url.user, password: @url.password }
    end

    def full_url
      @full_url ||= generate_full_url.to_s
    end

    private

    def parse_url(url)
      url             = url.strip
      match           = url.match(%r{\A(?:ssh|http(?:s?))\://(?:(.+)(?:@))?(.+)})
      raw_credentials = match[1] if match

      if raw_credentials.present?
        url.sub!("#{raw_credentials}@", '')

        user, password = raw_credentials.split(':')
        @credentials ||= { user: user, password: password }
      end

      url = Addressable::URI.parse(url)
      url.user = user
      url.password = password
      url
    end

    def generate_full_url
      return @url unless valid_credentials?
      @full_url = @url.dup
      @full_url.user = credentials[:user]
      @full_url.password = credentials[:password]
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
