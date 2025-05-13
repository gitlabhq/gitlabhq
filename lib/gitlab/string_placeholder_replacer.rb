# frozen_string_literal: true

module Gitlab
  class StringPlaceholderReplacer
    # This method accepts the following paras
    # - string: the string to be analyzed
    # - placeholder_regex: i.e. /(project_path|project_id|default_branch|commit_sha)/
    # - limit: limits the number of replacements in the string. Set to 0 for unlimited
    # - block: this block will be called with each placeholder found in the string using
    #   the placeholder regex. If the result of the block is nil, the original
    #   placeholder will be returned.

    def self.replace_string_placeholders(string, placeholder_regex = nil, limit: 0, &block)
      return string if string.blank? || placeholder_regex.blank? || !block

      replace_placeholders(string, placeholder_regex, limit: limit, &block)
    end

    def self.placeholder_full_regex(placeholder_regex)
      /%(\{|%7B)(#{placeholder_regex})(\}|%7D)/
    end

    class << self
      private

      # If the result of the block is nil, then the placeholder is returned
      def replace_placeholders(string, placeholder_regex, limit: 0, &block)
        Gitlab::Utils::Gsub
          .gsub_with_limit(string, placeholder_full_regex(placeholder_regex), limit: limit) do |match_data|
          yield(match_data[2]) || match_data[0]
        end
      end
    end
  end
end
