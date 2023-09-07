# frozen_string_literal: true

class LabelLink < ApplicationRecord
  include BulkInsertSafe
  include Importable

  belongs_to :target, polymorphic: true, inverse_of: :label_links # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :label

  validates :target, presence: true, unless: :importing?
  validates :label, presence: true, unless: :importing?

  scope :for_target, -> (target_id, target_type) { where(target_id: target_id, target_type: target_type) }

  # Example: Issues has at least one label within a project
  # > Issue.where(project_id: 100) # or any scope on issues
  # >  .where(LabelLink.by_target_for_exists_query('Issue', Issue.arel_table[:id]).arel.exists)
  scope :by_target_for_exists_query, -> (target_type, arel_join_column, label_ids = nil) do
    relation = LabelLink
      .where(target_type: target_type)
      .where(arel_table['target_id'].eq(arel_join_column))

    relation = relation.where(label_id: label_ids) if label_ids
    relation
  end
end

LabelLink.prepend_mod_with('LabelLink')
