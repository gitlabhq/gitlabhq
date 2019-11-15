# frozen_string_literal: true

class DescriptionVersion < ApplicationRecord
  belongs_to :issue
  belongs_to :merge_request

  validate :exactly_one_issuable

  def self.issuable_attrs
    %i(issue merge_request).freeze
  end

  def issuable
    issue || merge_request
  end

  private

  def exactly_one_issuable
    issuable_count = self.class.issuable_attrs.count { |attr| self["#{attr}_id"] }

    errors.add(:base, "Exactly one of #{self.class.issuable_attrs.join(', ')} is required") if issuable_count != 1
  end
end

DescriptionVersion.prepend_if_ee('EE::DescriptionVersion')
