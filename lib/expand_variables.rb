# frozen_string_literal: true

module ExpandVariables
  VariableExpansionError = Class.new(StandardError)

  VARIABLES_REGEXP = /\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/

  class << self
    def expand(value, variables, expand_file_refs: true, fail_on_masked: false)
      replace_with(value, variables) do |collection, last_match|
        match_or_blank_value(
          collection, last_match, expand_file_refs: expand_file_refs, fail_on_masked: fail_on_masked
        )
      end
    end

    def expand_existing(value, variables, expand_file_refs: true, fail_on_masked: false)
      replace_with(value, variables) do |collection, last_match|
        match_or_original_value(
          collection, last_match, expand_file_refs: expand_file_refs, fail_on_masked: fail_on_masked
        )
      end
    end

    def possible_var_reference?(value)
      return unless value

      %w[$ %].any? { |symbol| value.include?(symbol) }
    end

    private

    def replace_with(value, variables)
      # We lazily fabricate the variables collection in case there is no variable in the value string.
      # `collection` needs to be initialized to nil here
      # so that it is memoized in the closure block for `gsub`.
      collection = nil

      value.gsub(VARIABLES_REGEXP) do
        collection ||= Gitlab::Ci::Variables::Collection.fabricate(variables)
        yield(collection, Regexp.last_match)
      end
    end

    def match_or_blank_value(collection, last_match, expand_file_refs:, fail_on_masked:)
      match = last_match[1] || last_match[2]
      replacement = collection[match]

      if replacement.nil?
        nil
      elsif fail_on_masked && replacement.masked?
        raise VariableExpansionError, 'masked variables cannot be expanded'
      elsif replacement.file?
        expand_file_refs ? replacement.value : last_match
      else
        replacement.value
      end
    end

    def match_or_original_value(collection, last_match, expand_file_refs:, fail_on_masked:)
      match_or_blank_value(
        collection, last_match, expand_file_refs: expand_file_refs, fail_on_masked: fail_on_masked
      ) || last_match[0]
    end
  end
end
