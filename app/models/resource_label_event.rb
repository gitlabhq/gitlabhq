# frozen_string_literal: true

class ResourceLabelEvent < ResourceEvent
  include CacheMarkdownField
  include MergeRequestResourceEvent
  include Import::HasImportSource
  include FromUnion

  cache_markdown_field :reference

  belongs_to :label

  scope :inc_relations, -> { includes(:label, :user) }

  validates :label, presence: { unless: :importing? }, on: :create
  validate :exactly_one_issuable, unless: :importing?

  after_commit :broadcast_notes_changed, unless: :importing?

  enum action: {
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

  def project
    issuable.project
  end

  def group
    issuable.resource_parent if issuable.resource_parent.is_a?(Group)
  end

  def outdated_markdown?
    return true if label_id.nil? && reference.present?

    reference.nil? || latest_cached_markdown_version != cached_markdown_version
  end

  def banzai_render_context(field)
    super.merge(pipeline: :label, only_path: true, label_url_method: label_url_method)
  end

  def refresh_invalid_reference
    # label_id could be nullified on label delete
    self.reference = '' if label_id.nil?

    # reference is not set for events which were not rendered yet
    self.reference ||= label_reference

    if changed?
      save
    elsif invalidated_markdown_cache?
      refresh_markdown_cache!
    end
  end

  def self.visible_to_user?(user, events)
    ResourceLabelEvent.preload_label_subjects(events)

    events.select do |event|
      Ability.allowed?(user, :read_label, event)
    end
  end

  private

  def label_reference
    if local_label?
      label.to_reference(format: :id)
    elsif label.is_a?(GroupLabel)
      label.to_reference(label.group, target_container: resource_parent, format: :id)
    else
      label.to_reference(resource_parent, format: :id)
    end
  end

  def label_url_method
    return :project_merge_requests_url if issuable.is_a?(MergeRequest)

    issuable.project_id.nil? ? :group_work_items_url : :project_issues_url
  end

  def broadcast_notes_changed
    issuable.broadcast_notes_changed
  end

  def local_label?
    params = { include_ancestor_groups: true }
    if resource_parent.is_a?(Project)
      params[:project_id] = resource_parent.id
    else
      params[:group_id] = resource_parent.id
    end

    LabelsFinder.new(nil, params).execute(skip_authorization: true).where(id: label.id).any?
  end

  def resource_parent
    issuable.try(:resource_parent) || issuable.project || issuable.group
  end

  def discussion_id_key
    [self.class.name, created_at.to_f, user_id]
  end
end

ResourceLabelEvent.prepend_mod_with('ResourceLabelEvent')
