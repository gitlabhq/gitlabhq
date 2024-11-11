# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class EmailParticipants < Base
        def after_create
          return unless params[:operation] == :move
          return unless target_work_item.get_widget(:email_participants)

          work_item.email_participants.each_batch(of: BATCH_SIZE) do |email_participants_batch|
            ::IssueEmailParticipant.insert_all(new_work_item_email_participants(email_participants_batch))
          end
        end

        def post_move_cleanup
          work_item.email_participants.each_batch(of: BATCH_SIZE) do |email_participants_batch|
            email_participants_batch.delete_all
          end
        end

        private

        def new_work_item_email_participants(email_participants_batch)
          email_participants_batch.map do |email_participant|
            email_participant.attributes.except("id").tap { |ep| ep["issue_id"] = target_work_item.id }
          end
        end
      end
    end
  end
end
