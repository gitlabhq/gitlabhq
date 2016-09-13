module Gitlab
  class UrlSanitizer
    def self.sanitize(content)
      regexp = URI::Parser.new.make_regexp(['http', 'https', 'ssh', 'git'])

      content.gsub(regexp) { |url| new(url).masked_url }
    rescue Addressable::URI::InvalidURIError
      content.gsub(regexp, '')
    end

    def self.valid?(url)
      return false unless url

      Addressable::URI.parse(url.strip)

      true
    rescue Addressable::URI::InvalidURIError
      false
    end

    def initialize(url, credentials: nil)
      @url = Addressable::URI.parse(url.strip)
      @credentials = credentials
    end

    def sanitized_url
      @sanitized_url ||= safe_url.to_s
    end

    def masked_url
      url = @url.dup
      url.password = "*****" unless url.password.nil?
      url.user = "*****" unless url.user.nil?
      url.to_s
    end

    def credentials
      @credentials ||= { user: @url.user, password: @url.password }
    end

    def full_url
      @full_url ||= generate_full_url.to_s
    end

    private

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
