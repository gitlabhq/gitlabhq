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
        Feature.enabled?(:fips_mode, default_enabled: :yaml)
      end
    end
  end
end

# rubocop: enable Naming/FileName
