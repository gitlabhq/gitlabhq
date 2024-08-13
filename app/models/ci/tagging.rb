# frozen_string_literal: true

module Ci
  class Tagging < Ci::ApplicationRecord
    self.table_name = :taggings

    DEFAULT_CONTEXT = 'tags'

    belongs_to :tag, class_name: 'Ci::Tag'
    belongs_to :taggable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations -- existing

    validates :context, presence: true
    validates :tag_id, presence: true
    validates :tag_id, uniqueness: { scope: %i[taggable_type taggable_id context tagger_id tagger_type] }

    scope :by_contexts, ->(contexts) { where(context: contexts || DEFAULT_CONTEXT) }
    scope :by_context, ->(context = DEFAULT_CONTEXT) { by_contexts(context.to_s) }
  end
end
