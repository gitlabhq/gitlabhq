# frozen_string_literal: true

module Gitlab
  module Email
    module Hook
      class AdditionalHeadersInterceptor
        def self.delivering_email(message)
          message.header['Auto-Submitted'] ||= 'auto-generated'
          message.header['X-Auto-Response-Suppress'] ||= 'All'
        end
      end
    end
  end
end
