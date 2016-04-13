# I'm borrowing this class from: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3066
# So we should fix the conflict once the CE -> EE merge process starts.
module Gitlab
  class ImportUrl
    def initialize(url, credentials: nil)
      @url = URI.parse(url)
      @credentials = credentials
    end

    def sanitized_url
      @sanitized_url ||= safe_url.to_s
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
