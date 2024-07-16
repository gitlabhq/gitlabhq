# frozen_string_literal: true

module ServiceDeskSettings
  class UpdateService < BaseService
    include ::ServiceDesk::CustomEmails::Logger

    def execute
      settings = ServiceDeskSetting.safe_find_or_create_by!(project_id: project.id)

      params[:project_key] = nil if params[:project_key].blank?

      apply_feature_flag_restrictions!(
        feature_flag: :issue_email_participants,
        field: :add_external_participants_from_cc
      )

      # We want to know when custom email got enabled
      write_log_message = params[:custom_email_enabled].present? && !settings.custom_email_enabled?

      if settings.update(params)
        log_info if write_log_message

        ServiceResponse.success
      else
        ServiceResponse.error(message: settings.errors.full_messages.to_sentence)
      end
    end

    private

    def apply_feature_flag_restrictions!(feature_flag:, field:)
      return if Feature.enabled?(feature_flag, project)
      return unless params.include?(field)

      params.delete(field)
    end
  end
end
