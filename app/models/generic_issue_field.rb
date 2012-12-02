# == Schema Information
#
# Table name: generic_issue_fields
#
#  id          :integer          not null, primary key
#  title       :string(255)      not null
#  project_id  :integer          not null
#  description :string(255)
#
# Table name: generic_issue_field_values

class GenericIssueField < ActiveRecord::Base
  attr_accessible :title, :generic_issue_field_values_string, :generic_issue_field_value_ids, :generic_issue_field_values
  belongs_to :project
  has_many :generic_issue_field_values, :dependent => :destroy

  validates :title, presence: true
  validates :project_id, presence: true

  # this is the name of the attribute on an Issue instance that can be 
  # used to set or retrieve the value of this issue field
  def symbol_for_field
    return ('generic_issue_field_%s' % id).to_s
  end

  # this is the name of the attribute on an Issue instance that can be
  # used to get the id of that same value
  def symbol_for_field_value_id
    return ('generic_issue_field_%s_value_id' % id).to_s
  end

  # this is an attribute to get/set all the titles of the values
  # in one go as a newline separated list of titles
  def generic_issue_field_values_string
    return generic_issue_field_values.collect{|v| v.title}.join("\n")
  end

  def generic_issue_field_values_string= titles_string
    new_titles = titles_string.split("\n").collect{|v| v.chomp}
    ids_to_keep = generic_issue_field_value_ids.find{|id| new_titles.include? GenericIssueFieldValue.find_by_id(id).title}
    generic_issue_field_value_ids = ids_to_keep
    current_titles = generic_issue_field_values.collect{|v| v.title}
    new_titles.each do |t|
      if not current_titles.include? t then 
        generic_issue_field_values<<GenericIssueFieldValue.new(:generic_issue_field_id => id, :title => t)
      end
    end
  end
end

