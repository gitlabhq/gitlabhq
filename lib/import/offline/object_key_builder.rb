# frozen_string_literal: true

# This class standardizes object key generation for offline exports and imports. All built keys have the formats
#   - For non-batched relations: "#{export_prefix}/#{entity_prefix}/#{relation}.#{extension}"
#   - For batched relations: "#{export_prefix}/#{entity_prefix}/#{relation}/batch_#{batch_number}.#{extension}"
#   - For metadata.json: "#{export_prefix}/metadata.json.gz"
# `export_prefix` is the top-level prefix for all files that are a part of the same offline export
# Some examples:
#   - `2026-04-16_19-39-00_export_dJtnb3CV/group_1/self.json` - `self` relation (JSON format)
#   - `2026-04-16_19-39-00_export_dJtnb3CV/group_1/milestones.ndjson` - tree relation, single file
#   - `2026-04-16_19-39-00_export_dJtnb3CV/project_1/issues/batch_1.ndjson` - tree relation, batched
#   - `2026-04-16_19-39-00_export_dJtnb3CV/project_1/repository.tar.gz` - archive relation, single file
#   - `2026-04-16_19-39-00_export_dJtnb3CV/project_1/uploads/batch_1.tar.gz` - archive relation, batched
module Import
  module Offline
    class ObjectKeyBuilder
      BATCH_FILE_NAME_REGEX = Gitlab::UntrustedRegexp.new('\Abatch_(?P<number>\d+)\..+\z')

      ObjectKeyError = Class.new(StandardError)

      def initialize(configuration)
        @configuration = configuration
      end

      # Builds the object key for the metadata file.
      def metadata_object_key
        [configuration.export_prefix, 'metadata.json.gz'].join(
          ::Import::Clients::ObjectStorage::PREFIX_SEPARATOR
        )
      end

      # Builds the object key for uploading a relation file during export.
      # Derives the entity prefix directly from the portable being exported (e.g. "project_1", "group_5").
      #
      # @param portable [Group, Project] the entity being exported
      # @param relation [String] the relation name (e.g. "issues", "labels")
      # @param extension [String] the file extension including compression suffix (e.g. ".ndjson.gz")
      # @param batch_number [Integer, nil] the batch number for batched exports
      def upload_object_key(portable:, relation:, extension:, batch_number: nil)
        entity_prefix = "#{portable.class.name.downcase}_#{portable.id}"

        object_key(relation, extension, entity_prefix, batch_number: batch_number)
      end

      # Builds the object key for downloading a relation file during import.
      # Maps entity prefix from the configuration's entity_prefix_mapping originating from metadata.
      #
      # @param relation [String] the relation name (e.g. "issues", "labels")
      # @param extension [String] the file extension including compression suffix (e.g. ".ndjson.gz")
      # @param entity_source_full_path [String] the source full path of the entity (e.g. "group/subgroup/project")
      # @param batch_number [Integer, nil] the batch number for batched exports
      def download_object_key(relation:, extension:, entity_source_full_path:, batch_number: nil)
        entity_prefix = configuration.entity_prefix_for_path(entity_source_full_path)

        raise ObjectKeyError, "Entity prefix missing for #{entity_source_full_path}" if entity_prefix.blank?

        object_key(relation, extension, entity_prefix, batch_number: batch_number)
      end

      # Builds the object key prefix for a relation using the batched relation format. E.g.
      # '2026-04-16_19-39-00_export_dJtnb3CV/project_1/issues' is the batched object prefix for the object key
      # '2026-04-16_19-39-00_export_dJtnb3CV/project_1/issues/batch_1.ndjson'
      #
      # @param relation [String] the relation name (e.g., "issues", "merge_requests")
      # @param entity_prefix [String] the entity directory prefix (e.g., "project_1")
      # @return [String] the prefix (e.g., "2026-04-16_export_abc/project_1/issues")
      def batched_object_key_prefix(relation:, entity_prefix:)
        [configuration.export_prefix, entity_prefix, relation].join(::Import::Clients::ObjectStorage::PREFIX_SEPARATOR)
      end

      # Returns whether the given object key represents an unbatched (single-file) export
      # for the specified relation by checking if the filename without extension matches
      # the relation name exactly (e.g., "milestones.ndjson" matches relation "milestones").
      #
      # @param object_key [String] the full object key
      # @param relation [String] the relation name to check against
      # @return [Boolean]
      def unbatched_relation_key?(object_key, relation)
        filename(object_key).split('.').first == relation
      end

      # Extracts the batch number from a batched export object key.
      # Parses the filename against the pattern "batch_<number>.<ext>".
      #
      # @param object_key [String] the full object key (e.g., ".../issues/batch_3.ndjson")
      # @return [Integer, nil] the batch number, or nil if the key is not a batched file
      def batch_number(object_key)
        regexp_match = BATCH_FILE_NAME_REGEX.match(filename(object_key))

        regexp_match[:number].to_i if regexp_match
      end

      private

      attr_reader :configuration

      def object_key(relation, extension, entity_prefix, batch_number: nil)
        filename_parts = []
        filename_parts << configuration.export_prefix
        filename_parts << entity_prefix

        if batch_number.present?
          filename_parts << relation
          filename_parts << "batch_#{batch_number}#{extension}"
        else
          filename_parts << "#{relation}#{extension}"
        end

        filename_parts.join(::Import::Clients::ObjectStorage::PREFIX_SEPARATOR)
      end

      def filename(object_key)
        object_key.split(::Import::Clients::ObjectStorage::PREFIX_SEPARATOR).last
      end
    end
  end
end
