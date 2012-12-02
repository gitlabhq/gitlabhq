# == Schema Information
#
# Table name: issue_generic_issue_field_values
#
#  issue_id                     :integer not null
#  generic_issue_field_value_id :integer not null
#

class IssueGenericIssueFieldValue < ActiveRecord::Base
  belongs_to :generic_issue_field_value
  belongs_to :issue
end
