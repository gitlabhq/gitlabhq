# == Schema Information
#
# Table name: milestones
#
#  id          :integer          not null, primary key
#  title       :string(255)      not null
#  project_id  :integer          not null
#  description :text
#  due_date    :date
#  created_at  :datetime
#  updated_at  :datetime
#  state       :string(255)
#  iid         :integer
#

class Milestone < ActiveRecord::Base
  # Represents a "No Milestone" state used for filtering Issues and Merge
  # Requests that have no milestone assigned.
  MilestoneStruct = Struct.new(:title, :name, :id)
  None = MilestoneStruct.new('No Milestone', 'No Milestone', 0)
  Any = MilestoneStruct.new('Any Milestone', '', -1)

  include InternalId
  include Sortable
  include Referable
  include StripAttribute
  include Milestoneish

  belongs_to :project
  has_many :issues
  has_many :labels, -> { distinct.reorder('labels.title') },  through: :issues
  has_many :merge_requests
  has_many :participants, -> { distinct.reorder('users.name') }, through: :issues, source: :assignee

  scope :active, -> { with_state(:active) }
  scope :closed, -> { with_state(:closed) }
  scope :of_projects, ->(ids) { where(project_id: ids) }

  validates :title, presence: true, uniqueness: { scope: :project_id }
  validates :project, presence: true

  strip_attributes :title

  state_machine :state, initial: :active do
    event :close do
      transition active: :closed
    end

    event :activate do
      transition closed: :active
    end

    state :closed

    state :active
  end

  alias_attribute :name, :title

  class << self
    # Searches for milestones matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      t = arel_table
      pattern = "%#{query}%"

      where(t[:title].matches(pattern).or(t[:description].matches(pattern)))
    end
  end

  def self.reference_pattern
    nil
  end

  def self.link_reference_pattern
    super("milestones", /(?<milestone>\d+)/)
  end

  def to_reference(from_project = nil)
    escaped_title = self.title.gsub("]", "\\]")

    h = Gitlab::Application.routes.url_helpers
    url = h.namespace_project_milestone_url(self.project.namespace, self.project, self)

    "[#{escaped_title}](#{url})"
  end

  def reference_link_text(from_project = nil)
    self.title
  end

  def expired?
    if due_date
      due_date.past?
    else
      false
    end
  end

  def expires_at
    if due_date
      if due_date.past?
        "expired on #{due_date.to_s(:medium)}"
      else
        "expires on #{due_date.to_s(:medium)}"
      end
    end
  end

  def can_be_closed?
    active? && issues.opened.count.zero?
  end

  def is_empty?
    total_items_count.zero?
  end

  def author_id
    nil
  end

  # Sorts the issues for the given IDs.
  #
  # This method runs a single SQL query using a CASE statement to update the
  # position of all issues in the current milestone (scoped to the list of IDs).
  #
  # Given the ids [10, 20, 30] this method produces a SQL query something like
  # the following:
  #
  #     UPDATE issues
  #     SET position = CASE
  #       WHEN id = 10 THEN 1
  #       WHEN id = 20 THEN 2
  #       WHEN id = 30 THEN 3
  #       ELSE position
  #     END
  #     WHERE id IN (10, 20, 30);
  #
  # This method expects that the IDs given in `ids` are already Fixnums.
  def sort_issues(ids)
    pairs = []

    ids.each_with_index do |id, index|
      pairs << id
      pairs << index + 1
    end

    conditions = 'WHEN id = ? THEN ? ' * ids.length

    issues.where(id: ids).
      update_all(["position = CASE #{conditions} ELSE position END", *pairs])
  end
end
