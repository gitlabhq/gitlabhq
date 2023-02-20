# frozen_string_literal: true

module Exportable
  extend ActiveSupport::Concern

  def readable_records(association, current_user: nil)
    association_records = try(association)
    return unless association_records.present?

    if has_many_association?(association)
      DeclarativePolicy.user_scope do
        association_records.select { |record| readable_record?(record, current_user) }
      end
    else
      readable_record?(association_records, current_user) ? association_records : nil
    end
  end

  def exportable_association?(association, current_user: nil)
    return false unless respond_to?(association)
    return true if has_many_association?(association)

    readable = try(association)
    return true if readable.nil?

    readable_record?(readable, current_user)
  end

  def restricted_associations(keys)
    exportable_restricted_associations & keys
  end

  def has_many_association?(association_name)
    self.class.reflect_on_association(association_name)&.macro == :has_many
  end

  private

  def exportable_restricted_associations
    []
  end

  def readable_record?(record, user)
    if record.respond_to?(:exportable_record?)
      record.exportable_record?(user)
    else
      record.readable_by?(user)
    end
  end
end
