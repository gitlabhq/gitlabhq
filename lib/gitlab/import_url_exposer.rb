module Gitlab
  # Exposes an import URL that includes the credentials unencrypted.
  # Extracted to its own class to prevent unintended use.
  module ImportUrlExposer

    def self.expose(import_url:, credentials: )
      uri = URI.parse(import_url)
      uri.user = credentials[:user]
      uri.password = credentials[:password]
      uri
    end
  end
end
