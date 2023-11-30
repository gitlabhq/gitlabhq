# frozen_string_literal: true

module ServiceDesk
  module CustomEmailVerifications
    class BaseService < ::BaseProjectService
      include ::ServiceDesk::CustomEmails::Logger

      attr_reader :settings

      def initialize(project:, current_user: nil, params: {})
        super(project: project, current_user: current_user, params: params)

        @settings = project.service_desk_setting
      end

      private

      def notify_project_owners_and_user_with_email(email_method_name: nil, user: nil)
        owner_emails = project.owners.map(&:email)

        owner_emails << user.email if user.present?

        owner_emails.uniq(&:downcase).each do |email_address|
          Notify.try(email_method_name, settings, email_address).deliver_later
        end
      end

      def notify_project_owners_and_user_about_result(user: nil)
        notify_project_owners_and_user_with_email(
          email_method_name: :service_desk_verification_result_email,
          user: user
        )
      end

      def error_response(message)
        log_warning(error_message: message)
        ServiceResponse.error(message: message)
      end

      def error_not_verified(error_identifier)
        log_info(error_message: error_identifier.to_s)
        ServiceResponse.error(
          message: _('ServiceDesk|Custom email address could not be verified.'),
          reason: error_identifier.to_s
        )
      end

      def log_category
        'custom_email_verification'
      end
    end
  end
end
