# frozen_string_literal: true

class DescriptionVersion < ApplicationRecord
  include FromUnion

  attr_accessor :preloaded_issuable

  belongs_to :issue
  belongs_to :merge_request
  belongs_to :namespace

  validates :namespace, presence: true
  validate :exactly_one_issuable

  before_validation :ensure_namespace_id

  delegate :resource_parent, to: :issuable

  def self.issuable_attrs
    %i[issue merge_request].freeze
  end

  def issuable
    return preloaded_issuable if preloaded_issuable

    issue || merge_request
  end

  private

  def parent_namespace_id
    case issuable
    when Issue
      issuable.namespace_id
    when MergeRequest
      issuable.project.project_namespace_id
    end
  end

  def ensure_namespace_id
    return if namespace_id && namespace_id > 0

    self.namespace_id = parent_namespace_id
  end

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
