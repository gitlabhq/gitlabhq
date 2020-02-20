# frozen_string_literal: true

module BulkInsertSafe
  extend ActiveSupport::Concern

  # These are the callbacks we think safe when used on models that are
  # written to the database in bulk
  CALLBACK_NAME_WHITELIST = Set[
    :initialize,
    :validate,
    :validation,
    :find,
    :destroy
  ].freeze

  MethodNotAllowedError = Class.new(StandardError)

  class_methods do
    def set_callback(name, *args)
      unless _bulk_insert_callback_allowed?(name, args)
        raise MethodNotAllowedError.new(
          "Not allowed to call `set_callback(#{name}, #{args})` when model extends `BulkInsertSafe`." \
            "Callbacks that fire per each record being inserted do not work with bulk-inserts.")
      end

      super
    end

    private

    def _bulk_insert_callback_allowed?(name, args)
      _bulk_insert_whitelisted?(name) || _bulk_insert_saved_from_belongs_to?(name, args)
    end

    # belongs_to associations will install a before_save hook during class loading
    def _bulk_insert_saved_from_belongs_to?(name, args)
      args.first == :before && args.second.to_s.start_with?('autosave_associated_records_for_')
    end

    def _bulk_insert_whitelisted?(name)
      CALLBACK_NAME_WHITELIST.include?(name)
    end
  end
end
