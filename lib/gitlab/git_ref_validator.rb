# frozen_string_literal: true

# Gitaly note: JV: does not need to be migrated, works without a repo.

module Gitlab
  module GitRefValidator
    extend self

    EXPANDED_PREFIXES = %w[refs/heads/ refs/remotes/].freeze

    # Regex pattern for forbidden bytes (works on binary-encoded strings)
    # - \x00-\x1f: Control characters (bytes 0-31)
    # - \x7f: DEL character (byte 127)
    # - Special characters: space, ~, ^, :, ?, *, [, \
    FORBIDDEN_BYTES_REGEX = /[\x00-\x1f\x7f ~^:?*\[\\]/

    # Validates a given name against the git reference specification
    #
    # Returns true for a valid reference name, false otherwise
    def validate(ref_name, skip_head_ref_check: false)
      return false if ref_name.to_s.empty? # #blank? raises an ArgumentError for invalid encodings
      return false if ref_name.start_with?(*EXPANDED_PREFIXES)
      return false if ref_name == 'HEAD' && !skip_head_ref_check

      valid_ref_name?(ref_name)
    end

    def validate_merge_request_branch(ref_name)
      return false if ref_name.to_s.empty?

      if Feature.enabled?(:git_ref_validator_custom_validation, Feature.current_request)
        custom_valid_ref_name?(ref_name)
      else
        legacy_validate_merge_request_branch(ref_name)
      end
    end

    private

    def valid_ref_name?(ref_name)
      if Feature.enabled?(:git_ref_validator_custom_validation, Feature.current_request)
        custom_valid_ref_name?(ref_name)
      else
        legacy_valid_ref_name?(ref_name)
      end
    end

    # Legacy validation using Rugged for `validate` method
    # Has known bugs: allows DEL char (0x7F) and single '@'
    def legacy_valid_ref_name?(ref_name)
      return false if ref_name.start_with?('-')

      Rugged::Reference.valid_name?("refs/heads/#{ref_name}")
    rescue ArgumentError
      false
    end

    # Legacy validation using Rugged for `validate_merge_request_branch` method
    # Preserves original behavior: refs starting with refs/heads/ or refs/remotes/ are used as-is
    def legacy_validate_merge_request_branch(ref_name)
      return false if ref_name.start_with?('-')

      expanded_name = if ref_name.start_with?(*EXPANDED_PREFIXES)
                        ref_name
                      else
                        "refs/heads/#{ref_name}"
                      end

      Rugged::Reference.valid_name?(expanded_name)
    rescue ArgumentError
      false
    end

    # Custom validation according to git-check-ref-format rules
    # See: https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html
    #
    # Works at byte level to handle arbitrary byte sequences (not just valid UTF-8)
    #
    # This method validates UNQUALIFIED refs (e.g., "feature/branch") that will be
    # expanded to qualified refs (e.g., "refs/heads/feature/branch") before Git operations.
    # Therefore:
    # - Rule 2 (must contain '/') doesn't apply - enforced at qualified ref level
    # - Rule 9 (cannot be single '@') doesn't apply - "refs/heads/@" is not a single '@'
    def custom_valid_ref_name?(ref_name)
      # Convert to binary encoding to work with raw bytes
      bytes = ref_name.dup.force_encoding(Encoding::ASCII_8BIT)

      return false if bytes.start_with?('-') # Branch names cannot start with dash
      return false if bytes.end_with?('/', '.')
      return false if FORBIDDEN_BYTES_REGEX.match?(bytes)
      return false if contains_forbidden_sequences?(bytes)
      return false if has_invalid_path_components?(bytes)

      true
    end

    # Check for forbidden sequences: '..', '//', '@{'
    def contains_forbidden_sequences?(bytes)
      bytes.include?('..') || bytes.include?('//') || bytes.include?('@{')
    end

    # Check path components for:
    # - Starting with '.' (Rule 1)
    # - Ending with '.lock' (Rule 1)
    def has_invalid_path_components?(bytes)
      bytes.split('/').any? do |component|
        component.start_with?('.') || component.end_with?('.lock')
      end
    end
  end
end
