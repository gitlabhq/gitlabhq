module Gitlab
  class ImportUrlSanitizer
    def initialize(url)
      @url = URI.parse(url)
    end

    def sanitized_url
      @sanitized_url ||= safe_url.to_s
    end

    def credentials
      @credentials ||= { user: @url.user, password: @url.password }
    end

    private

    def safe_url
      safe_url = @url.dup
      safe_url.password = nil
      safe_url.user = nil
      safe_url
    end
  end
end