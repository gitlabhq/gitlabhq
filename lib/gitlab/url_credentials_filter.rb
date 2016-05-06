module Gitlab
  class UrlCredentialsFilter
    def self.process(content)
      regexp = URI::Parser.new.make_regexp(['http', 'https', 'ssh', 'git'])

      content.gsub(regexp) { |url| Gitlab::ImportUrl.new(url).sanitized_url }
    end
  end
end
