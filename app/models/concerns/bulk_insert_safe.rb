# frozen_string_literal: true

##
# A mixin for ActiveRecord models that enables callers to insert instances of the
# target class into the database en-bloc via the [bulk_insert] method.
#
# Upon inclusion in the target class, the mixin will perform a number of checks to
# ensure that the target is eligible for bulk insertions. For instance, it must not
# use ActiveRecord callbacks that fire between [save]s, since these would not run
# properly when instances are inserted in bulk.
#
# The mixin uses ActiveRecord 6's [InsertAll] type internally for bulk insertions.
# Unlike [InsertAll], however, it requires you to pass instances of the target type
# rather than row hashes, since it will run validations prior to insertion.
#
# @example
#
#   class MyRecord < ApplicationRecord
#     include BulkInsertSafe # must be included _last_ i.e. after any other concerns
#   end
#
#   # simple
#   MyRecord.bulk_insert!(items)
#
#   # with custom batch size
#   MyRecord.bulk_insert!(items, batch_size: 100)
#
#   # without validations
#   MyRecord.bulk_insert!(items, validate: false)
#
#   # with attribute hash modification
#   MyRecord.bulk_insert!(items) { |item_attrs| item_attrs['col'] = 42 }
#
#
module BulkInsertSafe
  extend ActiveSupport::Concern

  # These are the callbacks we think safe when used on models that are
  # written to the database in bulk
  ALLOWED_CALLBACKS = Set[
    :initialize,
    :validate,
    :validation,
    :find,
    :destroy
  ].freeze

  DEFAULT_BATCH_SIZE = 500

  MethodNotAllowedError = Class.new(StandardError)
  PrimaryKeySetError = Class.new(StandardError)

  class_methods do
    def insert_all_proxy_class
      @insert_all_proxy_class ||= Class.new(self) do
        attr_readonly :created_at
      end
    end

    def set_callback(name, *args)
      unless _bulk_insert_callback_allowed?(name, args)
        raise MethodNotAllowedError,
          "Not allowed to call `set_callback(#{name}, #{args})` when model extends `BulkInsertSafe`." \
            "Callbacks that fire per each record being inserted do not work with bulk-inserts."
      end

      super
    end

    # Inserts the given ActiveRecord [items] to the table mapped to this class.
    # Items will be inserted in batches of a given size, where insertion semantics are
    # "atomic across all batches".
    #
    # @param [Boolean] validate          Whether validations should run on [items]
    # @param [Integer] batch_size        How many items should at most be inserted at once
    # @param [Boolean] skip_duplicates   Marks duplicates as allowed, and skips inserting them
    # @param [Symbol]  returns           Pass :ids to return an array with the primary key values
    #                                    for all inserted records or nil to omit the underlying
    #                                    RETURNING SQL clause entirely.
    # @param [Symbol/Array] unique_by    Defines index or columns to use to consider item duplicate
    # @param [Proc]    handle_attributes Block that will receive each item attribute hash
    #                                    prior to insertion for further processing
    #
    # Unique indexes can be identified by columns or name:
    #  - unique_by: :isbn
    #  - unique_by: %i[ author_id name ]
    #  - unique_by: :index_books_on_isbn
    #
    # Note that this method will throw on the following occasions:
    # - [PrimaryKeySetError]            when primary keys are set on entities prior to insertion
    # - [ActiveRecord::RecordInvalid]   on entity validation failures
    # - [ActiveRecord::RecordNotUnique] on duplicate key errors
    #
    # @return true if operation succeeded, throws otherwise.
    #
    def bulk_insert!(
      items,
      validate: true,
      skip_duplicates: false,
      returns: nil,
      unique_by: nil,
      batch_size: DEFAULT_BATCH_SIZE,
      &handle_attributes
    )
      _bulk_insert_all!(
        items,
        validate: validate,
        on_duplicate: skip_duplicates ? :skip : :raise,
        returns: returns,
        unique_by: unique_by,
        batch_size: batch_size,
        &handle_attributes
      )
    end

    # Upserts the given ActiveRecord [items] to the table mapped to this class.
    # Items will be inserted or updated in batches of a given size,
    # where insertion semantics are "atomic across all batches".
    #
    # @param [Boolean] validate          Whether validations should run on [items]
    # @param [Integer] batch_size        How many items should at most be inserted at once
    # @param [Symbol/Array] unique_by    Defines index or columns to use to consider item duplicate
    # @param [Symbol]  returns           Pass :ids to return an array with the primary key values
    #                                    for all inserted or updated records or nil to omit the
    #                                    underlying RETURNING SQL clause entirely.
    # @param [Proc]    handle_attributes Block that will receive each item attribute hash
    #                                    prior to insertion for further processing
    #
    # Unique indexes can be identified by columns or name:
    #  - unique_by: :isbn
    #  - unique_by: %i[ author_id name ]
    #  - unique_by: :index_books_on_isbn
    #
    # Note that this method will throw on the following occasions:
    # - [PrimaryKeySetError]            when primary keys are set on entities prior to insertion
    # - [ActiveRecord::RecordInvalid]   on entity validation failures
    # - [ActiveRecord::RecordNotUnique] on duplicate key errors
    #
    # @return true if operation succeeded, throws otherwise.
    #
    def bulk_upsert!(
      items,
      unique_by:,
      returns: nil,
      validate: true,
      batch_size: DEFAULT_BATCH_SIZE,
      &handle_attributes
    )
      _bulk_insert_all!(
        items,
        validate: validate,
        on_duplicate: :update,
        returns: returns,
        unique_by: unique_by,
        batch_size: batch_size,
        &handle_attributes
      )
    end

    private

    def _bulk_insert_all!(items, on_duplicate:, returns:, unique_by:, validate:, batch_size:, &handle_attributes)
      return [] if items.empty?

      returning =
        case returns
        when :ids
          [primary_key]
        when nil
          false
        else
          returns
        end

      composite_primary_key = ::Gitlab.next_rails? && composite_primary_key?

      # Handle insertions for tables with a composite primary key
      primary_keys = connection.schema_cache.primary_keys(table_name)
      unique_by = primary_keys if unique_by.blank? && (composite_primary_key || primary_key != primary_keys)

      transaction do
        items.each_slice(batch_size).flat_map do |item_batch|
          attributes = _bulk_insert_item_attributes(item_batch, validate, &handle_attributes)

          ActiveRecord::InsertAll
              .new(
                insert_all_proxy_class,
                attributes,
                on_duplicate: on_duplicate,
                returning: returning,
                unique_by: unique_by
              )
              .execute
              .cast_values(insert_all_proxy_class.attribute_types).to_a
        end
      end
    end

    def _bulk_insert_item_attributes(items, validate_items)
      items.map do |item|
        item.validate! if validate_items

        attributes = {}
        column_names.each do |name|
          attributes[name] = item.read_attribute(name)
        end

        _bulk_insert_reject_primary_key!(attributes, item.class)

        yield attributes if block_given?

        attributes
      end
    end

    def _bulk_insert_reject_primary_key!(attributes, model_class)
      primary_key = model_class.primary_key
      existing_pk = attributes.delete(primary_key)
      if existing_pk
        if model_class.columns_hash[primary_key].serial?
          raise PrimaryKeySetError, "Primary key set: #{primary_key}:#{existing_pk}\n" \
            "#{primary_key} is a serial primary key, this is probably a mistake"
        else
          # If the PK is serial, then we need to delete it from attributes to avoid setting
          # explicit NULLs in the insert statement. If the PK is not serial, then we'll use
          # the value set in the attributes.
          attributes[primary_key] = existing_pk
        end
      end
    end

    def _bulk_insert_callback_allowed?(name, args)
      ALLOWED_CALLBACKS.include?(name) || _bulk_insert_saved_from_belongs_to?(name, args)
    end

    # belongs_to associations will install a before_save hook during class loading
    def _bulk_insert_saved_from_belongs_to?(name, args)
      args.first == :before && args.second.to_s.start_with?('autosave_associated_records_for_')
    end
  end
end
