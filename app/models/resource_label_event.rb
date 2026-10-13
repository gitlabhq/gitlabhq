# frozen_string_literal: true

class ResourceLabelEvent < ResourceEvent
  include MergeRequestResourceEvent
  include Import::HasImportSource
  include FromUnion

  belongs_to :label, inverse_of: :resource_label_events
  belongs_to :namespace

  scope :inc_relations, -> { includes(:label, :user) }
  scope :with_label_id, ->(label_id) { where(label_id: label_id) }

  validates :label, presence: { unless: :importing? }, on: :create
  validates_with ExactlyOnePresentValidator, fields: :issuable_id_attrs, unless: :importing?
  validates :namespace, presence: true

  before_validation :ensure_namespace_id
  # Bulk inserts bypass this; importers skip it to avoid a finder query per row.
  before_validation :ensure_reference, on: :create, unless: :importing?
  after_commit :broadcast_notes_changed, unless: :importing?

  enum :action, {
    add: 1,
    remove: 2
  }

  def self.issuable_attrs
    %i[issue merge_request].freeze
  end

  def self.preload_label_subjects(events)
    labels = events.map(&:label).compact
    project_labels, group_labels = labels.partition { |label| label.is_a? ProjectLabel }

    ActiveRecord::Associations::Preloader.new(records: project_labels, associations: { project: :project_feature }).call
    ActiveRecord::Associations::Preloader.new(records: group_labels, associations: :group).call
  end

  def issuable
    issue || merge_request
  end

  def synthetic_note_class
    LabelNote
  end

  def outdated_reference?
    (label_id.nil? && reference.present?) || reference.nil?
  end

  def refresh_invalid_reference
    # label_id could be nullified on label delete
    self.reference = '' if label_id.nil?

    # reference is not set for events which were not rendered yet
    self.reference ||= label_reference

    save if changed?
  end

  def self.reference_for(label, parent, local_label_ids)
    return '' if label.nil?

    if local_label_ids.include?(label.id)
      label.to_reference(format: :id)
    elsif label.is_a?(GroupLabel)
      label.to_reference(label.group, target_container: parent, format: :id)
    else
      label.to_reference(parent, format: :id)
    end
  end

  def self.preload_reference_containers(labels)
    project_labels, group_labels = labels.partition { |label| label.is_a?(ProjectLabel) }

    ActiveRecord::Associations::Preloader.new(
      records: project_labels, associations: { project: [:route, { namespace: :route }] }
    ).call
    ActiveRecord::Associations::Preloader.new(records: group_labels, associations: { group: :route }).call
  end

  # Must match LabelReferenceFilter#label_finder_params or bare ids won't render.
  def self.local_labels_finder_params(parent)
    return { include_ancestor_groups: true, project: parent } if parent.is_a?(Project)

    { include_ancestor_groups: true, group: parent, only_group_labels: true }
  end

  def self.visible_to_user?(user, events)
    ResourceLabelEvent.preload_label_subjects(events)

    events.select do |event|
      Ability.allowed?(user, :read_label, event)
    end
  end

  private

  def ensure_namespace_id
    self.namespace_id = Gitlab::Issuable::NamespaceGetter.new(issuable, allow_nil: true).namespace_id
  end

  def label_reference
    return '' if label.nil?

    local_label_ids = local_label? ? [label_id] : []

    self.class.reference_for(label, resource_parent, local_label_ids)
  end

  def ensure_reference
    return if reference || issuable.nil?

    self.reference = label_reference
  end

  def broadcast_notes_changed
    issuable.broadcast_notes_changed
  end

  def local_label?
    params = self.class.local_labels_finder_params(resource_parent)

    LabelsFinder.new(nil, params).execute(skip_authorization: true).id_in(label.id).any?
  end

  def resource_parent
    issuable.try(:resource_parent) || issuable.project || issuable.group
  end

  def discussion_id_key
    [self.class.name, created_at.to_f, user_id]
  end
end

ResourceLabelEvent.prepend_mod
