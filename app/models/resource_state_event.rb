# frozen_string_literal: true

class ResourceStateEvent < ResourceEvent
  include MergeRequestResourceEvent
  include Importable
  include Import::HasImportSource
  include FromUnion

  belongs_to :source_merge_request, class_name: 'MergeRequest', foreign_key: :source_merge_request_id
  belongs_to :namespace

  validates_with ExactlyOnePresentValidator, fields: :issuable_id_attrs, unless: :importing?
  validates :namespace, presence: true

  # state is used for issue and merge request states.
  enum :state, Issue.available_states.merge(MergeRequest.available_states).merge(reopened: 5)

  before_validation :ensure_namespace_id

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

  def ensure_namespace_id
    self.namespace_id = Gitlab::Issuable::NamespaceGetter.new(issuable, allow_nil: true).namespace_id
  end
end

ResourceStateEvent.prepend_mod
