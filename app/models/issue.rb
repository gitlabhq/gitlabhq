# == Schema Information
#
# Table name: issues
#
#  id            :integer          not null, primary key
#  title         :string(255)
#  assignee_id   :integer
#  author_id     :integer
#  project_id    :integer
#  created_at    :datetime
#  updated_at    :datetime
#  position      :integer          default(0)
#  branch_name   :string(255)
#  description   :text
#  milestone_id  :integer
#  state         :string(255)
#  iid           :integer
#  updated_by_id :integer
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class Issue < ActiveRecord::Base
  include InternalId
  include Issuable
  include Referable
  include Sortable
  include Taskable

  ActsAsTaggableOn.strict_case_match = true

  belongs_to :project
  validates :project, presence: true

  scope :of_group, ->(group) { where(project_id: group.project_ids) }
  scope :cared, ->(user) { where(assignee_id: user) }
  scope :open_for, ->(user) { opened.assigned_to(user) }

  state_machine :state, initial: :opened do
    event :close do
      transition [:reopened, :opened] => :closed
    end

    event :reopen do
      transition closed: :reopened
    end

    state :opened
    state :reopened
    state :closed
  end

  def hook_attrs
    attributes
  end

  def self.reference_prefix
    '#'
  end

  # Pattern used to extract `#123` issue references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}(?<issue>\d+)
    }x
  end

  def to_reference(from_project = nil)
    reference = "#{self.class.reference_prefix}#{iid}"

    if cross_project_reference?(from_project)
      reference = project.to_reference + reference
    end

    reference
  end

  # Reset issue events cache
  #
  # Since we do cache @event we need to reset cache in special cases:
  # * when an issue is updated
  # Events cache stored like  events/23-20130109142513.
  # The cache key includes updated_at timestamp.
  # Thus it will automatically generate a new fragment
  # when the event is updated because the key changes.
  def reset_events_cache
    Event.reset_event_cache_for(self)
  end

  # To allow polymorphism with MergeRequest.
  def source_project
    project
  end
end
