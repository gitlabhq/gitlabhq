module Gitlab
  # Exposes an import URL that includes the credentials unencrypted.
  # Extracted to its own class to prevent unintended use.
  module ImportUrlExposer
    extend self

    def expose(import_url:, credentials: )
      import_url.sub("//", "//#{parsed_credentials(credentials)}@")
    end

    private

    def parsed_credentials(credentials)
      credentials.values.join(":")
    end
  end
end