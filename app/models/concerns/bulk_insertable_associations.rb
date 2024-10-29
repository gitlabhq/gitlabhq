# frozen_string_literal: true

##
# ActiveRecord model classes can mix in this concern if they own associations
# who declare themselves to be eligible for bulk-insertion via [BulkInsertSafe].
# This allows the caller to write items from [has_many] associations en-bloc
# when the owner is first created.
#
# This implementation currently has a few limitations:
# - only works for [has_many] relations
# - does not support the [:through] option
# - it cannot bulk-insert items that had previously been saved, nor can the
#   owner of the association have previously been saved; if you attempt to
#   so, an error will be raised
#
# @example
#
#   class MergeRequestDiff < ApplicationRecord
#     include BulkInsertableAssociations
#
#     # target association class must `include BulkInsertSafe`
#     has_many :merge_request_diff_commits
#   end
#
#   diff = MergeRequestDiff.new(...)
#   diff.diff_commits << MergeRequestDiffCommit.build(...)
#   BulkInsertableAssociations.with_bulk_insert do
#     diff.save! # this will also write all `diff_commits` in bulk
#   end
#
# Note that just like [BulkInsertSafe.bulk_insert!], validations will run for
# all items that are scheduled for bulk-insertions.
#
module BulkInsertableAssociations
  extend ActiveSupport::Concern

  class << self
    def bulk_inserts_enabled?
      Thread.current['bulk_inserts_enabled']
    end

    # All associations that are [BulkInsertSafe] and that as a result of calls to
    # [save] or [save!] would be written to the database, will be inserted using
    # [bulk_insert!] instead.
    #
    # Note that this will only work for entities that have not been persisted yet.
    #
    # @param [Boolean] enabled When [true], bulk-inserts will be attempted within
    #                          the given block. If [false], bulk-inserts will be
    #                          disabled. This behavior can be nested.
    def with_bulk_insert(enabled: true)
      previous = bulk_inserts_enabled?
      Thread.current['bulk_inserts_enabled'] = enabled
      yield
    ensure
      Thread.current['bulk_inserts_enabled'] = previous
    end
  end

  def bulk_insert_associations!
    self.class.reflections.each do |_, reflection|
      _bulk_insert_association!(reflection)
    end
  end

  private

  def _bulk_insert_association!(reflection)
    return unless _association_supports_bulk_inserts?(reflection)

    association = self.association(reflection.name)
    association_items = association.target
    return if association_items.empty?

    if association_items.any?(&:persisted?)
      raise 'Bulk-insertion of already persisted association items is not currently supported'
    end

    _bulk_insert_configure_foreign_key(reflection, association_items)
    association.klass.bulk_insert!(association_items, validate: false)

    # reset relation:
    # 1. we successfully inserted all items
    # 2. when accessed we force to reload the relation
    association.reset
  end

  def _association_supports_bulk_inserts?(reflection)
    reflection.macro == :has_many &&
      reflection.klass < BulkInsertSafe &&
      !reflection.through_reflection? &&
      association_cached?(reflection.name)
  end

  def _bulk_insert_configure_foreign_key(reflection, items)
    primary_key_column = reflection.active_record_primary_key
    raise "Classes including `BulkInsertableAssociations` must define a `primary_key`" unless primary_key_column

    primary_key_value = self[primary_key_column]
    raise "No value found for primary key `#{primary_key_column}`" unless primary_key_value

    items.each do |item|
      item[reflection.foreign_key] = primary_key_value

      item[reflection.type] = self.class.polymorphic_name if reflection.type
    end
  end

  included do
    delegate :bulk_inserts_enabled?, to: BulkInsertableAssociations
    after_create :bulk_insert_associations!, if: :bulk_inserts_enabled?, prepend: true
  end
end
