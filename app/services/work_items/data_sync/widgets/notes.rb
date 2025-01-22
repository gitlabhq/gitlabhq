# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Notes < Base
        def after_save_commit
          return if params[:operation] == :clone && !params[:clone_with_notes]

          # Copying resource events regardless of notes widget being enabled as besides generating system notes
          # some of the resource events are also used to generate burn-down/burn-up charts.
          ::Gitlab::Issuable::Clone::CopyResourceEventsService.new(current_user, work_item, target_work_item).execute

          return unless target_work_item.get_widget(:notes)

          # copy notes
          ::WorkItems::DataSync::Handlers::Notes::CopyService.new(current_user, work_item, target_work_item).execute
        end

        def post_move_cleanup
          work_item.notes_with_associations.each_batch(of: BATCH_SIZE) do |notes_batch|
            # we need to explicitly delete AwardEmoji records for given notes, because there is no FK to take
            # care of cascade deleting AwardEmoji records when deleting a note.
            ::AwardEmoji.by_awardable('Note', notes_batch.select(:id)).delete_all
            # Upon note deletion FK cascade delete will also delete other records linked to the given note record.
            ::Note.id_in(notes_batch.select(:id)).delete_all
          end
        end
      end
    end
  end
end
