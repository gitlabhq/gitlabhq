# frozen_string_literal: true

module Gitlab
  module ExternallyStoredField
    extend ActiveSupport::Concern

    included do
      class_attribute :externally_stored_fields, default: Set.new
      class_attribute :external_storage_uploader_class

      before_save :set_file_store_from_uploader_config
      after_commit :persist_externally_stored_fields, on: [:create, :update]
      after_commit :remove_externally_stored_fields, on: :destroy
    end

    class_methods do
      def externally_stored_field(field)
        self.externally_stored_fields |= [field.to_sym]

        # Currently strings only; expand the signature if other types are needed.
        attribute field, :string

        # Rails' generated writer compares the new value against the in-memory "original" to decide
        # whether to mark the attribute as dirty. For virtual attributes that original starts as
        # nil, so without forcing a lazy load here, `record.content = nil` on a record with stored
        # content would not register as a change.
        define_method(:"#{field}=") do |value|
          load_externally_stored_fields
          super(value)
        end
      end
    end

    def externally_stored_field?(field_name)
      self.class.externally_stored_fields.include?(field_name.to_sym)
    end

    def reload(*)
      self.external_fields_loaded = false

      # The uploader caches the storage backend too, so we re-init it on next access.
      remove_instance_variable(:@external_storage_uploader) if instance_variable_defined?(:@external_storage_uploader)

      super
    end

    # `read_attribute` is the public API called by `[]`, while `_read_attribute` is called by AR's
    # generated readers (e.g. `record.content`) and by internal dirty-tracking comparisons. They
    # independently call `@attributes.fetch_value` so we must hook both to ensure lazy loading
    # fires on every path.
    def read_attribute(attr_name)
      ensure_externally_stored_fields_loaded(attr_name)
      super
    end

    def _read_attribute(attr_name)
      ensure_externally_stored_fields_loaded(attr_name)
      super
    end

    private

    attr_accessor :external_fields_loaded

    def ensure_externally_stored_fields_loaded(attr_name)
      load_externally_stored_fields if externally_stored_field?(attr_name)
    end

    def load_externally_stored_fields
      return if external_fields_loaded

      self.external_fields_loaded = true
      return unless persisted?

      payload = read_external_payload
      return unless payload

      # `@attributes.write_from_database` is the same internal API that AR uses to populate
      # attributes from query results, and is the only API with the right semantics: setting values
      # this way records them as the "original" values, so subsequent user writes are correctly
      # tracked as changes and round-trip writes are correctly de-tracked. If the internals change
      # in a future AR version, spec breakages will notify us.
      self.class.externally_stored_fields.each do |field|
        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- interacting with AR internals
        @attributes.write_from_database(field.to_s, payload[field.to_s])
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end
    end

    def external_storage_uploader
      @external_storage_uploader ||= begin
        klass = self.class.external_storage_uploader_class
        raise "#{self.class.name} must set external_storage_uploader_class" unless klass

        # Because we avoid using CarrierWave's `mount_uploader` -- it wants to store a filename
        # in our ActiveRecord record, but our filenames are deterministic so that's wasteful --
        # we have to manually instantiate the uploader.
        # `retrieve_from_store!` doesn't *actually* fetch anything from the store: it just sets
        # up the CarrierWave::Storage::Whatever instance so it's ready to be used.
        # `mount_uploader` would call this automatically if we were using it.
        uploader = klass.new(self)
        uploader.retrieve_from_store!(uploader.filename) if persisted?
        uploader
      end
    end

    def read_external_payload
      return unless external_storage_uploader.exists?

      Gitlab::Json.safe_parse(external_storage_uploader.read)
    rescue JSON::ParserError
      nil
    end

    def build_external_payload
      self.class.externally_stored_fields.each_with_object({}) do |field, payload|
        payload[field.to_s] = read_attribute(field)
      end
    end

    # When called with `updates:`, performs a read-merge-write against the stored payload.
    # This path is only reachable from `ExternalStorage::Extension#save_markdown` (i.e.
    # `refresh_markdown_cache!`), which is rare. Concurrent calls updating different fields
    # on the same record could clobber each other; there is no locking.
    def persist_external_payload(updates: nil)
      payload = if updates && persisted?
                  (read_external_payload || {}).merge(updates)
                else
                  build_external_payload
                end

      external_storage_uploader.store!(
        CarrierWaveStringFile.new(Gitlab::Json.dump(payload))
      )
    end

    # Set `file_store` as part of the normal AR save so it's committed atomically with
    # the rest of the record. The actual blob is written later in `after_commit`, so if
    # the process crashes between the DB commit and the blob upload, `file_store` will
    # reflect the intended storage backend even though the blob doesn't exist yet.
    def set_file_store_from_uploader_config
      return unless has_attribute?(:file_store)

      self.file_store = external_storage_uploader.object_store
    end

    def persist_externally_stored_fields
      return unless self.class.externally_stored_fields.any? { |f| saved_change_to_attribute?(f) }

      persist_external_payload
    end

    def remove_externally_stored_fields
      external_storage_uploader.remove!
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
    end
  end
end
