# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Notifications < Base
        def after_save_commit
          return unless params[:operation] == :move
          return unless target_work_item.get_widget(:notifications)

          work_item.subscriptions.each_batch(of: BATCH_SIZE) do |subscriptions_batch|
            ::Subscription.insert_all(new_work_item_subscriptions(subscriptions_batch))
          end

          # This replicates current move Issues::MoveService behaviour. This should be changed though to
          # move sent_notifications for any work_item that is being moved.
          return unless work_item.from_service_desk?

          # When moving sent notifications for any work item this can entail updating many records in some instances.
          # We should consider moving this to an async worker rather than have it run in a single request.
          work_item.sent_notifications.each_batch(of: BATCH_SIZE) do |sent_notifications_batch|
            # SentNotification does not have a sharding key yet.
            #
            # However when it has one it would potentially break
            # the immutability of the sharding key, because we need to update the record in place to keep the same
            # reply_key, which is a unique key.
            #
            # The alternative implies to create a new unique key and a mapping between the two keys, which requires
            # adding a new table or array column to keep the old keys, i.e. move development effort.
            ::SentNotification.upsert_all(
              new_work_item_sent_notifications(sent_notifications_batch), unique_by: :reply_key
            )
          end
        end

        def post_move_cleanup
          work_item.subscriptions.each_batch(of: BATCH_SIZE) do |subscriptions_batch|
            ::Subscription.id_in(subscriptions_batch.select(:id)).delete_all
          end

          # When moving sent notifications for any work item this can entail deleting many records in some instances.
          # We should consider moving this to an async worker rather than have it run in a single request.
          work_item.sent_notifications.each_batch(of: BATCH_SIZE) do |sent_notifications_batch|
            sent_notifications_batch.delete_all
          end
        end

        private

        def new_work_item_subscriptions(subscriptions_batch)
          subscriptions_batch.map do |subscription|
            subscription.attributes.except("id").tap do |ep|
              ep["subscribable_id"] = target_work_item.id
              ep["project_id"] = target_work_item.project_id
            end
          end
        end

        def new_work_item_sent_notifications(sent_notifications_batch)
          sent_notifications_batch.map do |sent_notification|
            sent_notification.attributes.except("id").tap do |ep|
              ep["noteable_id"] = target_work_item.id
              ep["project_id"] = target_work_item.project_id
            end
          end
        end
      end
    end
  end
end
