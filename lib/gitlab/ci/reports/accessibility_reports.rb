# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class AccessibilityReports
        attr_accessor :total, :passes, :errors
        attr_reader :urls

        def initialize
          @urls = {}
          @total = 0
          @passes = 0
          @errors = 0
        end

        def add_url(url, data)
          return if url.empty?

          urls[url] = data
        end
      end
    end
  end
end
