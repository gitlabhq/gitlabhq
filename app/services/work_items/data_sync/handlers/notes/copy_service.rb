# frozen_string_literal: true

# This service copies Notes from one Noteable to another.
#
# It expects the calling code to have performed the necessary authorization
# checks in order to allow the copy to happen.
module WorkItems
  module DataSync
    module Handlers
      module Notes
        class CopyService
          BATCH_SIZE = 50

          def initialize(current_user, source_noteable, target_noteable)
            @current_user = current_user
            @source_noteable = source_noteable
            @target_noteable = target_noteable
            @source_parent = source_noteable.resource_parent
            @target_parent = target_noteable.resource_parent
          end

          def execute
            return ServiceResponse.error(message: 'Noteables must be different') if source_noteable == target_noteable

            source_noteable.notes_with_associations.each_batch(of: BATCH_SIZE) do |notes_batch|
              next if notes_batch.empty?

              Note.transaction do
                notes_ids_map = allocate_new_ids(notes_batch, :id, 'notes_id_seq')
                ::Note.insert_all(new_notes(notes_batch, notes_ids_map))

                copy_notes_emoji(notes_ids_map)
                copy_notes_metadata(notes_ids_map)
                copy_notes_user_mentions(notes_ids_map)
              end
            end

            ServiceResponse.success
          end

          private

          attr_reader :current_user, :source_noteable, :target_noteable, :source_parent, :target_parent

          def copy_notes_emoji(notes_ids_map)
            notes_emoji = ::AwardEmoji.by_awardable('Note', notes_ids_map.keys)
            ::AwardEmoji.insert_all(new_notes_emoji(notes_emoji, notes_ids_map)) if notes_emoji.any?
          end

          def copy_notes_metadata(notes_ids_map)
            notes_metadata = ::SystemNoteMetadata.for_notes(notes_ids_map.keys)
            desc_versions_metadata = notes_metadata.filter_map do |metadata|
              metadata if metadata.description_version_id.present?
            end

            sequence_name = 'description_versions_id_seq'
            desc_version_ids_map = allocate_new_ids(desc_versions_metadata, :description_version_id, sequence_name)
            DescriptionVersion.insert_all(new_desc_versions(desc_version_ids_map)) if desc_version_ids_map.present?

            return if notes_metadata.blank?

            ::SystemNoteMetadata.insert_all(new_notes_metadata(notes_metadata, notes_ids_map, desc_version_ids_map))
          end

          def allocate_new_ids(collection, column_name, sequence_name)
            return {} if collection.blank?

            # rubocop: disable CodeReuse/ActiveRecord, Database/AvoidUsingPluckWithoutLimit -- collection size is limited
            ids = collection.pluck(column_name)
            # rubocop: enable CodeReuse/ActiveRecord, Database/AvoidUsingPluckWithoutLimit

            bind1 = ActiveRecord::Relation::QueryAttribute.new("sequence", sequence_name, ActiveRecord::Type::Value.new)
            bind2 = ActiveRecord::Relation::QueryAttribute.new("size", ids.size, ActiveRecord::Type::Value.new)

            allocated_ids = ApplicationRecord.connection.select_values(
              "SELECT NEXTVAL($1) from GENERATE_SERIES(1, $2)", "allocate_ids", [bind1, bind2]
            )

            ids.zip(allocated_ids).to_h
          end

          def new_notes(notes_batch, notes_ids_map)
            notes_batch.map do |note|
              note.attributes.tap do |attrs|
                attrs['id'] = notes_ids_map[note.id]
                attrs['noteable_id'] = target_noteable.id
                # we want this if we want to use this also to copy notes when promoting issue to epic
                attrs['noteable_type'] = target_noteable.class.base_class
                # need to use `try` to be able to handle Issue model and legacy Epic model instances
                attrs['project_id'] = target_noteable.try(:project_id)
                attrs['namespace_id'] = target_noteable.try(:namespace_id) || target_noteable.try(:group_id)
                attrs['imported_from'] = 'none' # maintaining current copy notes implementation

                # this data is not changed, but it is being serialized and we need it deserialized for bulk inserts
                attrs['position'] = note.attributes_before_type_cast['position']
                attrs['original_position'] = note.attributes_before_type_cast['original_position']
                attrs['change_position'] = note.attributes_before_type_cast['change_position']
                attrs['st_diff'] = note.attributes_before_type_cast['st_diff']
                attrs['cached_markdown_version'] = note.cached_markdown_version

                sanitized_note_params = sanitized_note_params(note)
                attrs['note'] = sanitized_note_params['note']
                attrs['note_html'] = sanitized_note_params['note_html']
              end
            end
          end

          def new_notes_emoji(notes_emoji, notes_ids_map)
            notes_emoji.map do |note_emoji|
              note_emoji.attributes.except('id').tap do |attrs|
                attrs['awardable_id'] = notes_ids_map[note_emoji.awardable_id]
              end
            end
          end

          def new_desc_versions(description_version_ids_map)
            DescriptionVersion.id_in(description_version_ids_map.keys).map do |description_version|
              description_version.attributes.tap do |attrs|
                attrs['id'] = description_version_ids_map[description_version.id]
                attrs['issue_id'] = target_noteable.id
              end
            end
          end

          def new_notes_metadata(system_notes_metadata, notes_ids_map, description_version_ids_map)
            system_notes_metadata.map do |note_metadata|
              note_metadata.attributes.except('id').tap do |attrs|
                attrs['note_id'] = notes_ids_map[note_metadata.note_id]
                attrs['description_version_id'] = description_version_ids_map[note_metadata.description_version_id]
              end
            end
          end

          def copy_notes_user_mentions(notes_ids_map)
            # rebuild user mentions for newly inserted notes
            new_user_mentions = new_user_mentions(notes_ids_map)
            target_noteable.user_mention_class.insert_all(new_user_mentions) if new_user_mentions.any?
          end

          def new_user_mentions(notes_ids_map)
            source_noteable.user_mentions.for_notes(notes_ids_map.keys).map do |user_mention|
              user_mention.attributes.except('id').tap do |attrs|
                attrs['issue_id'] = target_noteable.id
                attrs['note_id'] = notes_ids_map[user_mention.note_id]
              end
            end
          end

          def sanitized_note_params(note)
            MarkdownContentRewriterService.new(current_user, note, :note, source_parent, target_parent).execute
          end
        end
      end
    end
  end
end
