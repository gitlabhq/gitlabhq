# frozen_string_literal: true

module Gitlab
  module ImportExport
    module JSON
      class StreamingSerializer
        include Gitlab::ImportExport::CommandLineUtil

        BATCH_SIZE = 100
        SMALLER_BATCH_SIZE = 20

        def self.batch_size(exportable)
          if Feature.enabled?(:export_reduce_relation_batch_size, exportable)
            SMALLER_BATCH_SIZE
          else
            BATCH_SIZE
          end
        end

        class Raw < String
          def to_json(*_args)
            to_s
          end
        end

        def initialize(exportable, relations_schema, json_writer, exportable_path:)
          @exportable = exportable
          @exportable_path = exportable_path
          @relations_schema = relations_schema
          @json_writer = json_writer
        end

        def execute
          serialize_root

          includes.each do |relation_definition|
            serialize_relation(relation_definition)
          end
        end

        private

        attr_reader :json_writer, :relations_schema, :exportable

        def serialize_root
          attributes = exportable.as_json(
            relations_schema.merge(include: nil, preloads: nil))
          json_writer.write_attributes(@exportable_path, attributes)
        end

        def serialize_relation(definition)
          raise ArgumentError, 'definition needs to be Hash' unless definition.is_a?(Hash)
          raise ArgumentError, 'definition needs to have exactly one Hash element' unless definition.one?

          key, options = definition.first

          record = exportable.public_send(key) # rubocop: disable GitlabSecurity/PublicSend
          if record.is_a?(ActiveRecord::Relation)
            serialize_many_relations(key, record, options)
          elsif record.respond_to?(:each) # this is to support `project_members` that return an Array
            serialize_many_each(key, record, options)
          else
            serialize_single_relation(key, record, options)
          end
        end

        def serialize_many_relations(key, records, options)
          enumerator = Enumerator.new do |items|
            key_preloads = preloads&.dig(key)
            records = records.preload(key_preloads) if key_preloads

            records.find_each(batch_size: batch_size) do |record|
              items << Raw.new(record.to_json(options))
            end
          end

          json_writer.write_relation_array(@exportable_path, key, enumerator)
        end

        def serialize_many_each(key, records, options)
          enumerator = Enumerator.new do |items|
            records.each do |record|
              items << Raw.new(record.to_json(options))
            end
          end

          json_writer.write_relation_array(@exportable_path, key, enumerator)
        end

        def serialize_single_relation(key, record, options)
          json = Raw.new(record.to_json(options))

          json_writer.write_relation(@exportable_path, key, json)
        end

        def includes
          relations_schema[:include]
        end

        def preloads
          relations_schema[:preload]
        end

        def batch_size
          @batch_size ||= self.class.batch_size(@exportable)
        end
      end
    end
  end
end
