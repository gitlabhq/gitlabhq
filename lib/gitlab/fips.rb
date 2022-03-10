# rubocop: disable Naming/FileName
# frozen_string_literal: true

module Gitlab
  class FIPS
    # A simple utility class for FIPS-related helpers

    class << self
      # Returns whether we should be running in FIPS mode or not
      #
      # @return [Boolean]
      def enabled?
        # Attempt to auto-detect FIPS mode from OpenSSL
        return true if OpenSSL.fips_mode

        # Otherwise allow it to be set manually via the env vars
        return true if ENV["FIPS_MODE"] == "true"

        false
      end
    end
  end
end

# rubocop: enable Naming/FileName
