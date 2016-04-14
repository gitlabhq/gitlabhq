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
#  moved_to_id   :integer
#

require 'carrierwave/orm/activerecord'
require 'file_size_validator'

class Issue < ActiveRecord::Base
  include InternalId
  include Issuable
  include Referable
  include Sortable
  include Taskable
  include Elastic::IssuesSearch

  WEIGHT_RANGE = 1..9
  WEIGHT_ALL = 'Everything'
  WEIGHT_ANY = 'Any Weight'
  WEIGHT_NONE = 'No Weight'

  ActsAsTaggableOn.strict_case_match = true

  belongs_to :project
  belongs_to :moved_to, class_name: 'Issue'

  validates :project, presence: true

  scope :cared, ->(user) { where(assignee_id: user) }
  scope :open_for, ->(user) { opened.assigned_to(user) }
  scope :in_projects, ->(project_ids) { where(project_id: project_ids) }

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

  def self.visible_to_user(user)
    return where(confidential: false) if user.blank?
    return all if user.admin?

    where('issues.confidential = false OR (issues.confidential = true AND (issues.author_id = :user_id OR issues.assignee_id = :user_id OR issues.project_id IN(:project_ids)))', user_id: user.id, project_ids: user.authorized_projects.select(:id))
  end

  def self.reference_prefix
    '#'
  end

  # Pattern used to extract `#123` issue references from text
  #
  # This pattern supports cross-project references.
  def self.reference_pattern
    @reference_pattern ||= %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}(?<issue>\d+)
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= super("issues", /(?<issue>\d+)/)
  end

  def to_reference(from_project = nil)
    reference = "#{self.class.reference_prefix}#{iid}"

    if cross_project_reference?(from_project)
      reference = project.to_reference + reference
    end

    reference
  end

  def referenced_merge_requests(current_user = nil)
    @referenced_merge_requests ||= {}
    @referenced_merge_requests[current_user] ||= begin
      Gitlab::ReferenceExtractor.lazily do
        [self, *notes].flat_map do |note|
          note.all_references(current_user).merge_requests
        end
      end.sort_by(&:iid).uniq
    end
  end

  def related_branches
    project.repository.branch_names.select do |branch|
      branch =~ /\A#{iid}-(?!\d+-stable)/i
    end
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

  # From all notes on this issue, we'll select the system notes about linked
  # merge requests. Of those, the MRs closing `self` are returned.
  def closed_by_merge_requests(current_user = nil)
    return [] unless open?

    notes.system.flat_map do |note|
      note.all_references(current_user).merge_requests
    end.uniq.select { |mr| mr.open? && mr.closes_issue?(self) }
  end

  def self.weight_options
    [WEIGHT_ALL, WEIGHT_ANY, WEIGHT_NONE] + WEIGHT_RANGE.to_a
  end

  def moved?
    !moved_to.nil?
  end

  def can_move?(user, to_project = nil)
    if to_project
      return false unless user.can?(:admin_issue, to_project)
    end

    !moved? && persisted? &&
      user.can?(:admin_issue, self.project)
  end

  def to_branch_name
    "#{iid}-#{title.parameterize}"
  end

  def can_be_worked_on?(current_user)
    !self.closed? &&
      !self.project.forked? &&
      self.related_branches.empty? &&
      self.closed_by_merge_requests(current_user).empty?
  end
end
