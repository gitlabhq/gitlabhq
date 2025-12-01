# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Notifications < Base
        def after_save_commit
          return unless target_work_item.get_widget(:notifications)

          notify_participants

          return unless params[:operation] == :move

          work_item.subscriptions.each_batch(of: BATCH_SIZE) do |subscriptions_batch|
            ::Subscription.insert_all(new_work_item_subscriptions(subscriptions_batch))
          end

          # This replicates current move Issues::MoveService behaviour. This should be changed though to
          # move sent_notifications for any work_item that is being moved.
          return unless work_item.from_service_desk?

          # When moving sent notifications for any work item this can entail updating many records in some instances.
          # We should consider moving this to an async worker rather than have it run in a single request.
          work_item.sent_notifications.each_batch(column: :id, of: BATCH_SIZE) do |sent_notifications_batch|
            new_sent_notifications = new_work_item_sent_notifications(sent_notifications_batch)

            ::SentNotification.transaction do
              sent_notifications_batch.delete_all

              ::SentNotification.insert_all(new_sent_notifications)
            end
          end
        end

        def post_move_cleanup
          work_item.subscriptions.each_batch(of: BATCH_SIZE) do |subscriptions_batch|
            ::Subscription.id_in(subscriptions_batch.select(:id)).delete_all
          end

          # Until we implement async copy of sent_notifications, we'll continue to copy only
          # notifications for service_desk items. So only service_desk items can be skipped here as they were already
          # deleted in the transaction above
          return if work_item.from_service_desk?

          # When moving sent notifications for any work item this can entail deleting many records in some instances.
          # We should consider moving this to an async worker rather than have it run in a single request.
          work_item.sent_notifications.each_batch(column: :id, of: BATCH_SIZE) do |sent_notifications_batch|
            sent_notifications_batch.delete_all
          end
        end

        private

        def notify_participants
          operation = params[:operation]
          return unless [:move, :clone].include?(operation)

          arguments = [work_item, target_work_item, current_user]

          target_work_item.run_after_commit_or_now do
            NotificationService.new.async.issue_moved(*arguments) if operation == :move
            NotificationService.new.async.issue_cloned(*arguments) if operation == :clone
          end
        end

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
            sent_notification.attributes.except("id", "partition", "created_at").tap do |ep|
              ep["noteable_id"] = target_work_item.id
              ep["project_id"] = target_work_item.project_id
              ep["namespace_id"] = target_work_item.namespace_id
            end
          end
        end
      end
    end
  end
end
