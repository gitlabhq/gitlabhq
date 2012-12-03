# == Schema Information
#
# Table name: issues
#
#  id           :integer          not null, primary key
#  title        :string(255)
#  assignee_id  :integer
#  author_id    :integer
#  project_id   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  closed       :boolean          default(FALSE), not null
#  position     :integer          default(0)
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer
#

class Issue < ActiveRecord::Base
  include IssueCommonality
  include Votes

  attr_accessible :title, :assignee_id, :closed, :position, :description,
                  :milestone_id, :label_list, :author_id_of_changes

  acts_as_taggable_on :labels

  validates :description, length: { within: 0..2000 }

  def self.open_for(user)
    opened.assigned(user)
  end

  has_many :issue_generic_issue_field_values, :dependent => :destroy
  has_many :generic_issue_field_values, :through => :issue_generic_issue_field_values, :before_add => :clear_other_values
  belongs_to :project

  # we have to make sure that we clear the associations to other values
  # of the same field
  def clear_other_values new_generic_issue_field_value
    to_delete = generic_issue_field_values.find(:all, :conditions=>['generic_issue_field_id = ?', new_generic_issue_field_value.generic_issue_field.id])
    generic_issue_field_values.delete(to_delete)
  end

  # this method allows us to access the generic issue fields as if they are normal
  # attributes of an Issue instance. In reality, the number of fields and their
  # possible values are dynamically stored in tables and can be set by the administrator
  # on a per-project basis
  # Possible improvement: it would be nice to be able to abstract this logic away
  # from the Issue class and into its own namespace somewhere
  def method_missing(name, *args)
    method = (name.instance_of? Symbol) ? name.to_s : name
    # We compare the name of the method to all symbols for all the project's
    # generic issue fields
    project.generic_issue_fields.each do |generic_issue_field|
      if method == generic_issue_field.symbol_for_field.to_s
        # get a GenericIssueFieldValue
        return generic_issue_field_values.find(:first, :conditions=>['generic_issue_field_id = ?', generic_issue_field.id])
      elsif method.chomp("=") == generic_issue_field.symbol_for_field.to_s
        # set a GenericIssueFieldValue
        generic_issue_field_values << args[0]
        return
      elsif method == generic_issue_field.symbol_for_field_value_id.to_s
        # get the id of a generic_issue_field_value (useful for forms and such)
        return generic_issue_field_values.find(:first, :conditions=>['generic_issue_field_id = ?', generic_issue_field.id]).id
      elsif method.chomp('=') == generic_issue_field.symbol_for_field_value_id.to_s
        # set the id of a generic_issue_field_value (useful for forms and such)
        generic_issue_field_values << GenericIssueFieldValue.find_by_id(args[0])
        return
      end
    end
    super
  end

  # we have to override update_attributes because it chokes on the
  # dynamical attributes, for some reason. We update those in this
  # override and then call the superclass.
  def update_attributes (attributes)
    attributes.each do |key, value|
      project.generic_issue_fields.each do |generic_issue_field|
        if generic_issue_field.symbol_for_field == key then
          assigner = (generic_issue_field.symbol_for_field.to_s + '=').to_sym
          send(assigner, value)
          attributes.delete(key)
        elsif generic_issue_field.symbol_for_field_value_id == key then
          assigner = (generic_issue_field.symbol_for_field_value_id.to_s + '=').to_sym
          send(assigner, value)
          attributes.delete(key)
        end
      end
    end
    super
  end

end
