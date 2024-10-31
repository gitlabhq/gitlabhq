# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class AccessibilityReports
        attr_reader :urls, :error_message

        def initialize
          @urls = {}
          @error_message = nil
        end

        def add_url(url, data)
          if url.empty?
            set_error_message("Empty URL detected in gl-accessibility.json")
          else
            urls[url] = data
          end
        end

        def scans_count
          @urls.size
        end

        def passes_count
          @urls.count { |url, errors| errors.empty? }
        end

        def errors_count
          @urls.sum { |url, errors| errors.size }
        end

        def set_error_message(error)
          @error_message = error
        end

        def all_errors
          @urls.values.flatten
        end
      end
    end
  end
end
