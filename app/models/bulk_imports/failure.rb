# frozen_string_literal: true

class BulkImports::Failure < ApplicationRecord
  self.table_name = 'bulk_import_failures'

  belongs_to :entity,
    class_name: 'BulkImports::Entity',
    foreign_key: :bulk_import_entity_id,
    inverse_of: :failures,
    optional: false

  validates :entity, presence: true

  def relation
    pipeline_relation || default_relation
  end

  private

  def pipeline_relation
    klass = pipeline_class.constantize

    return unless klass.ancestors.include?(BulkImports::Pipeline)

    klass.relation
  rescue NameError
    nil
  end

  def default_relation
    pipeline_class.demodulize.chomp('Pipeline').underscore
  end
end
