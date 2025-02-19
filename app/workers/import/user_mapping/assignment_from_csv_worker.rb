# frozen_string_literal: true

module Import
  module UserMapping
    class AssignmentFromCsvWorker
      include ApplicationWorker

      data_consistency :delayed
      idempotent!
      feature_category :importers

      sidekiq_retries_exhausted do |job|
        new.perform_failure(*job['args'])
      end

      def perform(current_user_id, group_id, upload_id)
        @current_user = UserFinder.new(current_user_id).find_by_id
        @group = Group.find_by_id(group_id)
        upload = Upload.find_by_id(upload_id)

        if upload.nil?
          send_failure_email
          log_upload_missing(group)
          return
        end

        results = Import::SourceUsers::BulkReassignFromCsvService.new(
          current_user,
          group,
          upload
        ).execute

        if results.success?
          send_results_email(results)
          clear_upload(upload)
        else
          log_failure(results.message)
          perform_failure(current_user_id, group_id, upload_id)
        end
      end

      def perform_failure(current_user_id, group_id, upload_id)
        @current_user = UserFinder.new(current_user_id).find_by_id
        @group = Group.find_by_id(group_id)
        send_failure_email

        upload = Upload.find_by_id(upload_id)
        clear_upload(upload) if upload
      end

      private

      attr_reader :current_user, :group

      def send_results_email(_results)
        # Not implemented yet. To be resolved by:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/458841
      end

      def send_failure_email
        Notify.csv_placeholder_reassignment_failed(current_user.id, group.id).deliver_later
      end

      def clear_upload(upload)
        upload.destroy! if upload
      end

      def log_failure(message)
        ::Import::Framework::Logger.error(
          message: message
        )
      end

      def log_upload_missing(group)
        ::Import::Framework::Logger.error(
          message: "No reassignment CSV upload found for <Group id=#{group.id}>"
        )
      end
    end
  end
end
