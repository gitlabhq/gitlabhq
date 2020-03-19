# frozen_string_literal: true

module Gitlab
  module ImportExport
    module JSON
      class StreamingSerializer
        include Gitlab::ImportExport::CommandLineUtil

        BATCH_SIZE = 100

        class Raw < String
          def to_json(*_args)
            to_s
          end
        end

        def initialize(exportable, relations_schema, json_writer)
          @exportable = exportable
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
          json_writer.set(attributes)
        end

        def serialize_relation(definition)
          raise ArgumentError, 'definition needs to be Hash' unless definition.is_a?(Hash)
          raise ArgumentError, 'definition needs to have exactly one Hash element' unless definition.one?

          key, options = definition.first

          record = exportable.public_send(key) # rubocop: disable GitlabSecurity/PublicSend
          if record.is_a?(ActiveRecord::Relation)
            serialize_many_relations(key, record, options)
          else
            serialize_single_relation(key, record, options)
          end
        end

        def serialize_many_relations(key, records, options)
          key_preloads = preloads&.dig(key)
          records = records.preload(key_preloads) if key_preloads

          records.find_each(batch_size: BATCH_SIZE) do |record|
            json = Raw.new(record.to_json(options))

            json_writer.append(key, json)
          end
        end

        def serialize_single_relation(key, record, options)
          json = Raw.new(record.to_json(options))

          json_writer.write(key, json)
        end

        def includes
          relations_schema[:include]
        end

        def preloads
          relations_schema[:preload]
        end
      end
    end
  end
end
