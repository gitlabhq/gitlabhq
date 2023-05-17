# frozen_string_literal: true

# Gitaly note: JV: does not need to be migrated, works without a repo.

module Gitlab
  module GitRefValidator
    extend self

    EXPANDED_PREFIXES = %w[refs/heads/ refs/remotes/].freeze
    DISALLOWED_PREFIXES = %w[-].freeze

    # Validates a given name against the git reference specification
    #
    # Returns true for a valid reference name, false otherwise
    def validate(ref_name, skip_head_ref_check: false)
      return false if ref_name.to_s.empty? # #blank? raises an ArgumentError for invalid encodings
      return false if ref_name.start_with?(*(EXPANDED_PREFIXES + DISALLOWED_PREFIXES))
      return false if ref_name == 'HEAD' && !skip_head_ref_check

      begin
        Rugged::Reference.valid_name?("refs/heads/#{ref_name}")
      rescue ArgumentError
        false
      end
    end

    def validate_merge_request_branch(ref_name)
      return false if ref_name.to_s.empty?
      return false if ref_name.start_with?(*DISALLOWED_PREFIXES)

      expanded_name = if ref_name.start_with?(*EXPANDED_PREFIXES)
                        ref_name
                      else
                        "refs/heads/#{ref_name}"
                      end

      begin
        Rugged::Reference.valid_name?(expanded_name)
      rescue ArgumentError
        false
      end
    end
  end
end
