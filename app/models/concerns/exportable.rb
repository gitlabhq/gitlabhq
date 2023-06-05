# frozen_string_literal: true

module Exportable
  extend ActiveSupport::Concern

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

  def to_authorized_json(keys_to_authorize, current_user, options)
    modified_options = filtered_associations_opts(options, keys_to_authorize)
    record_hash = as_json(modified_options).with_indifferent_access

    keys_to_authorize.each do |key|
      next unless record_hash.key?(key)

      record_hash[key] = authorized_association_records(key, current_user, options)
    end

    record_hash.to_json
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

  def has_many_association?(association_name)
    self.class.reflect_on_association(association_name)&.macro == :has_many
  end

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

  def authorized_association_records(key, current_user, options)
    records = readable_records(key, current_user: current_user)
    empty_assoc = has_many_association?(key) ? [] : nil
    return empty_assoc unless records.present?

    assoc_opts = association_options(key, options)&.dig(key)
    records.as_json(assoc_opts)
  end

  def filtered_associations_opts(options, associations)
    options_copy = options.deep_dup

    associations.each do |key|
      assoc_opts = association_options(key, options_copy)
      next unless assoc_opts

      assoc_opts[key] = { only: [:id] }
    end

    options_copy
  end

  def association_options(key, options)
    options[:include].find { |assoc| assoc.key?(key) }
  end
end
