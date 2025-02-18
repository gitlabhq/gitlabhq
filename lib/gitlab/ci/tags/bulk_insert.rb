# frozen_string_literal: true

module Gitlab
  module Ci
    module Tags
      class BulkInsert
        include Gitlab::Utils::StrongMemoize

        TAGGINGS_BATCH_SIZE = 1000
        TAGS_BATCH_SIZE = 500

        attr_reader :config

        def self.bulk_insert_tags!(taggables, config: nil)
          Gitlab::Ci::Tags::BulkInsert.new(taggables, config: config).insert!
        end

        def initialize(taggables, config: nil)
          @taggables = taggables
          @config = config || ConfigurationFactory.new(taggables.first).build
        end

        def insert!
          return false if tag_list_by_taggable.empty?

          persist_build_tags!
        end

        private

        attr_reader :taggables

        delegate :join_model, to: :config

        def tag_list_by_taggable
          strong_memoize(:tag_list_by_taggable) do
            taggables.each.with_object({}) do |taggable, acc|
              tag_list = taggable.tag_list
              next unless tag_list

              acc[taggable] = tag_list
            end
          end
        end

        def persist_build_tags!
          all_tags = tag_list_by_taggable.values.flatten.uniq.reject(&:blank?)
          tag_records_by_name = create_tags(all_tags).index_by(&:name)
          taggings = build_taggings(tag_records_by_name)

          join_model.bulk_insert!(
            taggings,
            validate: false,
            skip_duplicates: true,
            unique_by: config.unique_by,
            batch_size: TAGGINGS_BATCH_SIZE,
            returns: :id
          )

          true
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def create_tags(tags)
          existing_tag_records = ::Ci::Tag.where(name: tags).to_a
          missing_tags = detect_missing_tags(tags, existing_tag_records)
          return existing_tag_records if missing_tags.empty?

          missing_tags
            .map { |tag| { name: tag } }
            .each_slice(TAGS_BATCH_SIZE) do |tags_attributes|
              ::Ci::Tag.insert_all!(tags_attributes)
            end

          ::Ci::Tag.where(name: tags).to_a
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def build_taggings(tag_records_by_name)
          accumulator = []

          taggables.each do |taggable|
            tag_list = tag_list_by_taggable[taggable]
            next unless tag_list

            tags = tag_records_by_name.values_at(*tag_list)
            tags.each do |tag|
              accumulator << new_taggings_record(tag, taggable)
            end
          end

          accumulator
        end

        def new_taggings_record(tag, taggable)
          attributes = { tag_id: tag.id }
          attributes.merge!(config.attributes_map(taggable))

          join_model.new(attributes)
        end

        def detect_missing_tags(tags, tag_records)
          if tags.size != tag_records.size
            tags - tag_records.map(&:name)
          else
            []
          end
        end
      end
    end
  end
end
