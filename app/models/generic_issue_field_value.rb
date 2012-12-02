# == Schema Information
#
# Table name: generic_issue_field_values
#
#  id                      :integer          not null, primary key
#  generic_field_value_id  :integer          not null
#  title                   :string(255)      not null
#  description             :string(255)

class GenericIssueFieldValue < ActiveRecord::Base
  attr_accessible :generic_issue_field, :generic_issue_field_id, :title
  belongs_to :generic_issue_field, :dependent => :destroy
  has_many :issue_generic_issue_field_values, :dependent => :destroy
  has_many :issues, :through => :issue_generic_issue_field_values

  validates :title, presence: true
  validates :generic_issue_field, presence: true
end
