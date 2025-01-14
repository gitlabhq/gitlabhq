# frozen_string_literal: true

module Projects
  module ImportExport
    class ImportCompletionNotificationWorker
      include ApplicationWorker

      idempotent!
      data_consistency :delayed
      urgency :low
      feature_category :importers

      attr_reader :project, :user_mapping_enabled, :notify_group_owners, :safe_import_url

      def perform(project_id, params = {})
        @project = Project.find_by_id(project_id)
        @user_mapping_enabled = params['user_mapping_enabled']
        @notify_group_owners = params['notify_group_owners']
        @safe_import_url = params['safe_import_url']

        return unless project
        return unless project.notify_project_import_complete?

        send_completion_notification
      end

      private

      def send_completion_notification
        completion_notification_recipients.each do |user|
          Notify
            .project_import_complete(project.id, user.id, user_mapping_enabled, safe_import_url)
            .deliver_later
        end
      end

      def completion_notification_recipients
        recipients = []
        recipients << project.creator if project.creator.human?

        if user_mapping_enabled && notify_group_owners
          project.root_ancestor.owners.each do |owner|
            recipients |= [owner] if owner.human?
          end
        end

        recipients
      end
    end
  end
end
