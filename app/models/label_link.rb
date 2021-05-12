# frozen_string_literal: true

class LabelLink < ApplicationRecord
  include BulkInsertSafe
  include Importable

  belongs_to :target, polymorphic: true, inverse_of: :label_links # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :label

  validates :target, presence: true, unless: :importing?
  validates :label, presence: true, unless: :importing?

  scope :for_target, -> (target_id, target_type) { where(target_id: target_id, target_type: target_type) }
end
