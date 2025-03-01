# frozen_string_literal: true

require 'ssrf_filter'

# Later versions of ssrf_filter no longer patch SSLSocket. See:
# https://github.com/arkadiyt/ssrf_filter/pull/73 and
# https://github.com/ruby/net-http/issues/141.
raise 'ssrf_filter patch no longer needed' if Gem::Version.new(SsrfFilter::VERSION) >= Gem::Version.new('1.2.0')

# Disable the ssrf_filter patch because it does exactly the same thing as
# gems/gitlab-http/lib/hostname_override_patch.rb does, except it lazily patches
# HTTP requests upon the first request.
class SsrfFilter
  module Patch
    module SSLSocket
      def self.apply!; end
    end
  end
end
