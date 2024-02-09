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
    importing_relation = pipeline_relation || default_relation

    return importing_relation unless subrelation

    "#{importing_relation}, #{subrelation}"
  end

  def exception_message=(message)
    super(::Projects::ImportErrorFilter.filter_message(message).truncate(255))
  end

  def source_title=(title)
    super(title&.truncate(255, omission: ''))
  end

  def source_url=(url)
    super(url&.truncate(255, omission: ''))
  end

  def subrelation=(url)
    super(url&.truncate(255, omission: ''))
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
