# frozen_string_literal: true

module Gitlab
  module Ci
    module Tags
      class BulkInsert
        include Gitlab::Utils::StrongMemoize

        TAGGINGS_BATCH_SIZE = 1000
        TAGS_BATCH_SIZE = 500

        def self.bulk_insert_tags!(taggables)
          Gitlab::Ci::Tags::BulkInsert.new(taggables).insert!
        end

        def initialize(taggables)
          @taggables = taggables
        end

        def insert!
          return false if tag_list_by_taggable.empty?

          persist_build_tags!
        end

        private

        attr_reader :taggables

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
          taggings = build_taggings_attributes(tag_records_by_name)

          return false if taggings.empty?

          taggings.each_slice(TAGGINGS_BATCH_SIZE) do |taggings_slice|
            ActsAsTaggableOn::Tagging.insert_all!(taggings_slice)
          end

          true
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def create_tags(tags)
          existing_tag_records = ActsAsTaggableOn::Tag.where(name: tags).to_a
          missing_tags = detect_missing_tags(tags, existing_tag_records)
          return existing_tag_records if missing_tags.empty?

          missing_tags
            .map { |tag| { name: tag } }
            .each_slice(TAGS_BATCH_SIZE) do |tags_attributes|
              ActsAsTaggableOn::Tag.insert_all!(tags_attributes)
            end

          ActsAsTaggableOn::Tag.where(name: tags).to_a
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def build_taggings_attributes(tag_records_by_name)
          taggings = taggables.flat_map do |taggable|
            tag_list = tag_list_by_taggable[taggable]
            next unless tag_list

            tags = tag_records_by_name.values_at(*tag_list)
            taggings_for(tags, taggable)
          end

          taggings.compact!
          taggings
        end

        def taggings_for(tags, taggable)
          tags.map do |tag|
            {
              tag_id: tag.id,
              taggable_type: taggable.class.base_class.name,
              taggable_id: taggable.id,
              created_at: Time.current,
              context: 'tags'
            }
          end
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
