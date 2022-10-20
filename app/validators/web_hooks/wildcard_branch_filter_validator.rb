# frozen_string_literal: true

# WildcardBranchFilterValidator
#
# Custom validator for wildcard branch filter. Squishes whitespace and ignores
# empty string. This only checks that a string is a valid wildcard git branch
# like "feature/login" and "feature/*". It doesn't check whether a branch already
# exists.
#
# Example:
#
#   class Webhook < ActiveRecord::Base
#     validates :push_events_branch_filter, "web_hooks/wildcard_branch_filter": true
#   end
#
module WebHooks
  class WildcardBranchFilterValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      value.squish! unless value.nil?

      return unless value.present?

      value_without_wildcards = value.tr('*', 'x')

      unless Gitlab::GitRefValidator.validate(value_without_wildcards)
        record.errors.add(attribute, "is not a valid branch name")
      end

      return if value.length <= 4000

      record.errors.add(attribute, "is longer than the allowed length of 4000 characters.")
    end
  end
end
