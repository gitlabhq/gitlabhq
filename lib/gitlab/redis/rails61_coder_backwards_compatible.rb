# frozen_string_literal: true

module Gitlab
  module Redis
    module Rails61CoderBackwardsCompatible
      # This module extends Rails61Coder (https://github.com/rails/rails/blob/v7.0.8.7/activesupport/lib/active_support/cache.rb#L874)
      # that supports reading cache from format_version 7.1.
      # The backwards compatibility prevents older GitLab version to crash when reading caches
      # that were written in 7.1 format from newer GitLab version (GitLab 18.0+).
      extend self
      include ActiveSupport::Cache::Coders::Rails61Coder

      SIGNATURE = "\x00\x11".b.freeze # https://github.com/rails/rails/blob/v7.1.5.1/activesupport/lib/active_support/cache/coder.rb#L66
      def load(dumped)
        # return nil to force a cache miss, subsequent dump will be written in 6.1 format and will be cache hits
        return if signature_from_7_1?(dumped)

        super
      end

      private

      def signature_from_7_1?(dumped)
        dumped.is_a?(String) && dumped.start_with?(SIGNATURE)
      end
    end
  end
end
