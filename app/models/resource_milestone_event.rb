# frozen_string_literal: true

class ResourceMilestoneEvent < ResourceTimeboxEvent
  include EachBatch
  include Import::HasImportSource

  belongs_to :milestone
  belongs_to :issue
  belongs_to :merge_request
  belongs_to :namespace

  validates :issue, presence: true, unless: :merge_request
  validates :merge_request, presence: true, unless: :issue
  validates :namespace, presence: true
  validates :issue, absence: {
    message: ->(_object, _data) { _("can't be specified if a merge request was already provided") }
  }, if: :merge_request

  before_validation :ensure_namespace_id

  scope :include_relations, -> { includes(:user, milestone: [:project, :group]) }

  # state is used for issue and merge request states.
  enum :state, Issue.available_states.merge(MergeRequest.available_states)

  def milestone_title
    milestone&.title
  end

  def milestone_parent
    milestone&.parent
  end

  def synthetic_note_class
    MilestoneNote
  end

  private

  def ensure_namespace_id
    # Due to how these records are created. I think it's better to always assign the right namespace before validation
    # instead of only doing it conditionally. These records never get updated.
    self.namespace_id = Gitlab::Issuable::NamespaceGetter.new(issuable, allow_nil: true).namespace_id
  end
end

ResourceMilestoneEvent.prepend_mod
