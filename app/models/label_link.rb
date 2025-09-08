# frozen_string_literal: true

class LabelLink < ApplicationRecord
  include BulkInsertSafe
  include Importable
  include FromUnion
  include EachBatch

  belongs_to :target, polymorphic: true, inverse_of: :label_links # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :label
  belongs_to :namespace
  # rubocop:disable Rails/InverseOf -- needed for unified association
  belongs_to :own_label, foreign_key: :label_id, class_name: 'Label'
  # rubocop:enable Rails/InverseOf

  validates :target, presence: true, unless: :skip_validate_import?
  validates :label, presence: true, unless: :skip_validate_import?
  validates :namespace, presence: true, unless: :skip_validate_import?

  before_validation :ensure_namespace_id

  scope :by_targets, ->(targets) { where(target: targets) }
  scope :for_target, ->(target_id, target_type) { where(target_id: target_id, target_type: target_type) }
  scope :with_label, -> { preload(:label) }

  # Example: Issues has at least one label within a project
  # > Issue.where(project_id: 100) # or any scope on issues
  # >  .where(LabelLink.by_target_for_exists_query('Issue', Issue.arel_table[:id]).arel.exists)
  scope :by_target_for_exists_query, ->(target_type, arel_join_column, label_ids = nil) do
    relation = LabelLink
      .where(target_type: target_type)
      .where(arel_table['target_id'].eq(arel_join_column)).select("label_id")

    relation = relation.where(label_id: label_ids) if label_ids
    relation
  end

  private

  def skip_validate_import?
    return false if Feature.enabled?(:validate_label_link_parent_presence_on_import, :instance)

    importing?
  end

  def ensure_namespace_id
    self.namespace_id = Gitlab::Issuable::NamespaceGetter.new(target, allow_nil: true).namespace_id
  end
end

LabelLink.prepend_mod
