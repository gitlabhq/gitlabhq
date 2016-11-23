require 'carrierwave/orm/activerecord'

class Issue < ActiveRecord::Base
  include InternalId
  include Issuable
  include Referable
  include Sortable
  include Spammable
  include FasterCacheKeys

  DueDateStruct = Struct.new(:title, :name).freeze
  NoDueDate     = DueDateStruct.new('No Due Date', '0').freeze
  AnyDueDate    = DueDateStruct.new('Any Due Date', '').freeze
  Overdue       = DueDateStruct.new('Overdue', 'overdue').freeze
  DueThisWeek   = DueDateStruct.new('Due This Week', 'week').freeze
  DueThisMonth  = DueDateStruct.new('Due This Month', 'month').freeze

  ActsAsTaggableOn.strict_case_match = true

  belongs_to :project
  belongs_to :moved_to, class_name: 'Issue'

  has_many :events, as: :target, dependent: :destroy

  has_many :merge_requests_closing_issues, class_name: 'MergeRequestsClosingIssues', dependent: :delete_all

  validates :project, presence: true

  scope :cared, ->(user) { where(assignee_id: user) }
  scope :open_for, ->(user) { opened.assigned_to(user) }
  scope :in_projects, ->(project_ids) { where(project_id: project_ids) }

  scope :without_due_date, -> { where(due_date: nil) }
  scope :due_before, ->(date) { where('issues.due_date < ?', date) }
  scope :due_between, ->(from_date, to_date) { where('issues.due_date >= ?', from_date).where('issues.due_date <= ?', to_date) }

  scope :order_due_date_asc, -> { reorder('issues.due_date IS NULL, issues.due_date ASC') }
  scope :order_due_date_desc, -> { reorder('issues.due_date IS NULL, issues.due_date DESC') }

  scope :created_after, -> (datetime) { where("created_at >= ?", datetime) }

  attr_spammable :title, spam_title: true
  attr_spammable :description, spam_description: true

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

  class << self
    private

    # Returns the project that the current scope belongs to if any, nil otherwise.
    #
    # Examples:
    # - my_project.issues.without_due_date.owner_project => my_project
    # - Issue.all.owner_project => nil
    def owner_project
      # No owner if we're not being called from an association
      return unless all.respond_to?(:proxy_association)

      owner = all.proxy_association.owner

      # Check if the association is or belongs to a project
      if owner.is_a?(Project)
        owner
      else
        begin
          owner.association(:project).target
        rescue ActiveRecord::AssociationNotFoundError
          nil
        end
      end
    end
  end

  def self.visible_to_user(user)
    return where('issues.confidential IS NULL OR issues.confidential IS FALSE') if user.blank?
    return all if user.admin?

    # Check if we are scoped to a specific project's issues
    if owner_project
      if owner_project.authorized_for_user?(user, Gitlab::Access::REPORTER)
        # If the project is authorized for the user, they can see all issues in the project
        return all
      else
        # else only non confidential and authored/assigned to them
        return where('issues.confidential IS NULL OR issues.confidential IS FALSE
          OR issues.author_id = :user_id OR issues.assignee_id = :user_id',
          user_id: user.id)
      end
    end

    where('
      issues.confidential IS NULL
      OR issues.confidential IS FALSE
      OR (issues.confidential = TRUE
        AND (issues.author_id = :user_id
          OR issues.assignee_id = :user_id
          OR issues.project_id IN(:project_ids)))',
      user_id: user.id,
      project_ids: user.authorized_projects(Gitlab::Access::REPORTER).select(:id))
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

  def self.reference_valid?(reference)
    reference.to_i > 0 && reference.to_i <= Gitlab::Database::MAX_INT_VALUE
  end

  def self.project_foreign_key
    'project_id'
  end

  def self.sort(method, excluded_labels: [])
    case method.to_s
    when 'due_date_asc' then order_due_date_asc
    when 'due_date_desc' then order_due_date_desc
    else
      super
    end
  end

  def to_reference(from_project = nil)
    reference = "#{self.class.reference_prefix}#{iid}"

    if cross_project_reference?(from_project)
      reference = project.to_reference + reference
    end

    reference
  end

  def referenced_merge_requests(current_user = nil)
    ext = all_references(current_user)

    notes_with_associations.each do |object|
      object.all_references(current_user, extractor: ext)
    end

    ext.merge_requests.sort_by(&:iid)
  end

  # All branches containing the current issue's ID, except for
  # those with a merge request open referencing the current issue.
  def related_branches(current_user)
    branches_with_iid = project.repository.branch_names.select do |branch|
      branch =~ /\A#{iid}-(?!\d+-stable)/i
    end

    branches_with_merge_request = self.referenced_merge_requests(current_user).map(&:source_branch)

    branches_with_iid - branches_with_merge_request
  end

  # To allow polymorphism with MergeRequest.
  def source_project
    project
  end

  # From all notes on this issue, we'll select the system notes about linked
  # merge requests. Of those, the MRs closing `self` are returned.
  def closed_by_merge_requests(current_user = nil)
    return [] unless open?

    ext = all_references(current_user)

    notes.system.each do |note|
      note.all_references(current_user, extractor: ext)
    end

    merge_requests = ext.merge_requests.select(&:open?)
    if merge_requests.any?
      ids = MergeRequestsClosingIssues.where(merge_request_id: merge_requests.map(&:id), issue_id: id).pluck(:merge_request_id)
      merge_requests.select { |mr| mr.id.in?(ids) }
    else
      []
    end
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
    if self.confidential?
      "#{iid}-confidential-issue"
    else
      "#{iid}-#{title.parameterize}"
    end
  end

  def can_be_worked_on?(current_user)
    !self.closed? &&
      !self.project.forked? &&
      self.related_branches(current_user).empty? &&
      self.closed_by_merge_requests(current_user).empty?
  end

  # Returns `true` if the current issue can be viewed by either a logged in User
  # or an anonymous user.
  def visible_to_user?(user = nil)
    return false unless project.feature_available?(:issues, user)

    user ? readable_by?(user) : publicly_visible?
  end

  def overdue?
    due_date.try(:past?) || false
  end

  # Only issues on public projects should be checked for spam
  def check_for_spam?
    project.public?
  end

  def as_json(options = {})
    super(options).tap do |json|
      json[:subscribed] = subscribed?(options[:user], project) if options.has_key?(:user) && options[:user]

      if options.has_key?(:labels)
        json[:labels] = labels.as_json(
          project: project,
          only: [:id, :title, :description, :color, :priority],
          methods: [:text_color]
        )
      end
    end
  end

  private

  # Returns `true` if the given User can read the current Issue.
  #
  # This method duplicates the same check of issue_policy.rb
  # for performance reasons, check commit: 002ad215818450d2cbbc5fa065850a953dc7ada8
  # Make sure to sync this method with issue_policy.rb
  def readable_by?(user)
    if user.admin?
      true
    elsif project.owner == user
      true
    elsif confidential?
      author == user ||
        assignee == user ||
        project.team.member?(user, Gitlab::Access::REPORTER)
    else
      project.public? ||
        project.internal? && !user.external? ||
        project.team.member?(user)
    end
  end

  # Returns `true` if this Issue is visible to everybody.
  def publicly_visible?
    project.public? && !confidential?
  end
end
