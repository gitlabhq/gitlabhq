# frozen_string_literal: true

# This model is not used yet, it will be used for:
# https://gitlab.com/gitlab-org/gitlab-ce/issues/48483
class ResourceLabelEvent < ActiveRecord::Base
  include Importable
  include Gitlab::Utils::StrongMemoize
  include CacheMarkdownField

  cache_markdown_field :reference

  belongs_to :user
  belongs_to :issue
  belongs_to :merge_request
  belongs_to :label

  scope :created_after, ->(time) { where('created_at > ?', time) }

  validates :user, presence: { unless: :importing? }, on: :create
  validates :label, presence: { unless: :importing? }, on: :create
  validate :exactly_one_issuable

  after_save :expire_etag_cache
  after_destroy :expire_etag_cache

  enum action: {
    add: 1,
    remove: 2
  }

  def self.issuable_attrs
    %i(issue merge_request).freeze
  end

  def issuable
    issue || merge_request
  end

  # create same discussion id for all actions with the same user and time
  def discussion_id(resource = nil)
    strong_memoize(:discussion_id) do
      Digest::SHA1.hexdigest([self.class.name, created_at, user_id].join("-"))
    end
  end

  def project
    issuable.project
  end

  def group
    issuable.group if issuable.respond_to?(:group)
  end

  def outdated_markdown?
    return true if label_id.nil? && reference.present?

    reference.nil? || latest_cached_markdown_version != cached_markdown_version
  end

  def banzai_render_context(field)
    super.merge(pipeline: 'label', only_path: true)
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

  private

  def label_reference
    if local_label?
      label.to_reference(format: :id)
    elsif label.is_a?(GroupLabel)
      label.to_reference(label.group, target_project: resource_parent, format: :id)
    else
      label.to_reference(resource_parent, format: :id)
    end
  end

  def exactly_one_issuable
    issuable_count = self.class.issuable_attrs.count { |attr| self["#{attr}_id"] }

    return true if issuable_count == 1

    # if none of issuable IDs is set, check explicitly if nested issuable
    # object is set, this is used during project import
    if issuable_count == 0 && importing?
      issuable_count = self.class.issuable_attrs.count { |attr| self.public_send(attr) } # rubocop:disable GitlabSecurity/PublicSend

      return true if issuable_count == 1
    end

    errors.add(:base, "Exactly one of #{self.class.issuable_attrs.join(', ')} is required")
  end

  def expire_etag_cache
    issuable.expire_note_etag_cache
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
    issuable.project || issuable.group
  end
end
