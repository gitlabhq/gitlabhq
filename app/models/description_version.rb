# frozen_string_literal: true

class DescriptionVersion < ApplicationRecord
  include FromUnion

  belongs_to :issue
  belongs_to :merge_request

  validate :exactly_one_issuable

  delegate :resource_parent, to: :issuable

  def self.issuable_attrs
    %i[issue merge_request].freeze
  end

  def issuable
    issue || merge_request
  end

  private

  def exactly_one_issuable
    issuable_count = self.class.issuable_attrs.count { |attr| self["#{attr}_id"] }

    if issuable_count != 1
      errors.add(
        :base,
        _("Exactly one of %{attributes} is required") %
          { attributes: self.class.issuable_attrs.join(', ') }
      )
    end
  end
end

DescriptionVersion.prepend_mod
