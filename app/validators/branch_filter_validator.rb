# frozen_string_literal: true

# BranchFilterValidator
#
# Custom validator for branch names. Squishes whitespace and ignores empty
# string.  This only checks that a string is a valid git branch name. It does
# not check whether a branch already exists.
#
# Example:
#
#   class Webhook < ActiveRecord::Base
#     validates :push_events_branch_filter, branch_name: true
#   end
#
class BranchFilterValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    value.squish! unless value.nil?

    if value.present?
      value_without_wildcards = value.tr('*', 'x')

      unless Gitlab::GitRefValidator.validate(value_without_wildcards)
        record.errors.add(attribute, "is not a valid branch name")
      end

      unless value.length <= 4000
        record.errors.add(attribute, "is longer than the allowed length of 4000 characters.")
      end
    end
  end

  private

  def contains_wildcard?(value)
    value.include?('*')
  end
end
