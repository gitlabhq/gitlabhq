# frozen_string_literal: true

class ResourceStateEvent < ResourceEvent
  include MergeRequestResourceEvent
  include Importable
  include Import::HasImportSource
  include FromUnion

  belongs_to :source_merge_request, class_name: 'MergeRequest', foreign_key: :source_merge_request_id
  belongs_to :namespace

  validate :exactly_one_issuable, unless: :importing?
  validates :namespace, presence: true

  # state is used for issue and merge request states.
  enum :state, Issue.available_states.merge(MergeRequest.available_states).merge(reopened: 5)

  before_validation :ensure_namespace_id
  after_create :issue_usage_metrics

  scope :merged_with_no_event_source, -> do
    where(state: :merged, source_merge_request: nil, source_commit: nil)
  end

  def self.issuable_attrs
    %i[issue merge_request].freeze
  end

  def issuable
    issue || merge_request
  end

  def for_issue?
    issue_id.present?
  end

  def synthetic_note_class
    StateNote
  end

  private

  def parent_namespace_id
    case issuable
    when Issue
      issuable.namespace_id
    when MergeRequest
      issuable.project.project_namespace_id
    end
  end

  def ensure_namespace_id
    self.namespace_id = parent_namespace_id
  end

  def issue_usage_metrics
    return unless for_issue?

    case state
    when 'closed'
      issue_usage_counter.track_issue_closed_action(author: user, project: issue.project)
    when 'reopened'
      issue_usage_counter.track_issue_reopened_action(author: user, project: issue.project)
    else
      # no-op, nothing to do, not a state we're tracking
    end
  end

  def issue_usage_counter
    Gitlab::UsageDataCounters::IssueActivityUniqueCounter
  end
end

ResourceStateEvent.prepend_mod_with('ResourceStateEvent')
