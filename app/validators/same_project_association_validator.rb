# frozen_string_literal: true

# SameProjectAssociationValidator
#
# Custom validator to validate that the same project associated with
# the record is also associated with the value
#
# Example:
# class ZoomMeeting < ApplicationRecord
#   belongs_to :project, optional: false
#   belongs_to :issue, optional: false

#   validates :issue, same_project_association: true
# end
class SameProjectAssociationValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if record.project == value&.project

    record.errors.add(attribute, 'must associate the same project')
  end
end
