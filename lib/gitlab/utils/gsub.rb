# frozen_string_literal: true

module Gitlab
  module Utils
    module Gsub
      extend self

      # This performs the same basic function as a `gsub`. However this version
      # allows us to break out of the replacement loop when the limit is reached.
      # This is the same algorithm used for Gitlab::UntrustedRegexp.replace_gsub
      def gsub_with_limit(text, pattern, limit:)
        new_text = +''
        remainder = text
        count = 0

        matched = remainder.match(pattern)

        until matched.nil? || matched.to_a.compact.empty?
          new_text << matched.pre_match
          remainder = matched.post_match

          new_text << (yield(matched) || '').to_s

          if limit > 0
            count += 1
            break if count >= limit
          end

          matched = remainder.match(pattern)
        end

        new_text << remainder
      end
    end
  end
end
