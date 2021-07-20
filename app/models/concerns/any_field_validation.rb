# frozen_string_literal: true

# This module enables a record to be valid if any field is present
#
# Overwrite one_of_required_fields to set one of which fields must be present
module AnyFieldValidation
  extend ActiveSupport::Concern

  included do
    validate :any_field_present
  end

  private

  def any_field_present
    return unless one_of_required_fields.all? { |field| self[field].blank? }

    errors.add(:base, _("At least one field of %{one_of_required_fields} must be present") %
      { one_of_required_fields: one_of_required_fields })
  end

  def one_of_required_fields
    raise NotImplementedError
  end
end
