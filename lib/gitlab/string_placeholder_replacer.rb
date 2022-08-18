# frozen_string_literal: true

module Gitlab
  class StringPlaceholderReplacer
    # This method accepts the following paras
    # - string: the string to be analyzed
    # - placeholder_regex: i.e. /%{project_path|project_id|default_branch|commit_sha}/
    # - block: this block will be called with each placeholder found in the string using
    # the placeholder regex. If the result of the block is nil, the original
    # placeholder will be returned.

    def self.replace_string_placeholders(string, placeholder_regex = nil, &block)
      return string if string.blank? || placeholder_regex.blank? || !block

      replace_placeholders(string, placeholder_regex, &block)
    end

    class << self
      private

      # If the result of the block is nil, then the placeholder is returned
      def replace_placeholders(string, placeholder_regex, &block)
        string.gsub(/%{(#{placeholder_regex})}/) do |arg|
          yield($~[1]) || arg
        end
      end
    end
  end
end
