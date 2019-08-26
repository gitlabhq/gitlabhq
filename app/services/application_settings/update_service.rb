# frozen_string_literal: true

module ApplicationSettings
  class UpdateService < ApplicationSettings::BaseService
    include ValidatesClassificationLabel

    attr_reader :params, :application_setting

    def execute
      validate_classification_label(application_setting, :external_authorization_service_default_label) unless bypass_external_auth?

      if application_setting.errors.any?
        return false
      end

      update_terms(@params.delete(:terms))

      add_to_outbound_local_requests_whitelist(@params.delete(:add_to_outbound_local_requests_whitelist))

      if params.key?(:performance_bar_allowed_group_path)
        params[:performance_bar_allowed_group_id] = performance_bar_allowed_group_id
      end

      if usage_stats_updated? && !params.delete(:skip_usage_stats_user)
        params[:usage_stats_set_by_user_id] = current_user.id
      end

      @application_setting.update(@params)
    end

    private

    def usage_stats_updated?
      params.key?(:usage_ping_enabled) || params.key?(:version_check_enabled)
    end

    def add_to_outbound_local_requests_whitelist(values)
      values_array = Array(values).reject(&:empty?)
      return if values_array.empty?

      @application_setting.add_to_outbound_local_requests_whitelist(values_array)
    end

    def update_terms(terms)
      return unless terms.present?

      # Avoid creating a new terms record if the text is exactly the same.
      terms = terms.strip
      return if terms == @application_setting.terms

      ApplicationSetting::Term.create(terms: terms)
      @application_setting.reset_memoized_terms
    end

    def performance_bar_allowed_group_id
      performance_bar_enabled = !params.key?(:performance_bar_enabled) || params.delete(:performance_bar_enabled)
      group_full_path = params.delete(:performance_bar_allowed_group_path)
      return unless Gitlab::Utils.to_boolean(performance_bar_enabled)

      Group.find_by_full_path(group_full_path)&.id if group_full_path.present?
    end

    def bypass_external_auth?
      params.key?(:external_authorization_service_enabled) && !Gitlab::Utils.to_boolean(params[:external_authorization_service_enabled])
    end
  end
end
