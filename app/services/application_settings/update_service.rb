# frozen_string_literal: true

module ApplicationSettings
  class UpdateService < ApplicationSettings::BaseService
    include ValidatesClassificationLabel

    attr_reader :params, :application_setting

    MARKDOWN_CACHE_INVALIDATING_PARAMS = %w(asset_proxy_enabled asset_proxy_url asset_proxy_secret_key asset_proxy_whitelist).freeze

    def execute
      validate_classification_label(application_setting, :external_authorization_service_default_label) unless bypass_external_auth?

      if application_setting.errors.any?
        return false
      end

      update_terms(@params.delete(:terms))

      add_to_outbound_local_requests_whitelist(@params.delete(:add_to_outbound_local_requests_whitelist))

      if params.key?(:performance_bar_allowed_group_path)
        group_id = process_performance_bar_allowed_group_id

        return false if application_setting.errors.any?

        params[:performance_bar_allowed_group_id] = group_id
      end

      if usage_stats_updated? && !params.delete(:skip_usage_stats_user)
        params[:usage_stats_set_by_user_id] = current_user.id
      end

      @application_setting.assign_attributes(params)

      if invalidate_markdown_cache?
        @application_setting[:local_markdown_version] = @application_setting.local_markdown_version + 1
      end

      @application_setting.save
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

    def invalidate_markdown_cache?
      !params.key?(:local_markdown_version) &&
        (@application_setting.changes.keys & MARKDOWN_CACHE_INVALIDATING_PARAMS).any?
    end

    def update_terms(terms)
      return unless terms.present?

      # Avoid creating a new terms record if the text is exactly the same.
      terms = terms.strip
      return if terms == @application_setting.terms

      ApplicationSetting::Term.create(terms: terms)
      @application_setting.reset_memoized_terms
    end

    def process_performance_bar_allowed_group_id
      group_full_path = params.delete(:performance_bar_allowed_group_path)
      enable_param_on = Gitlab::Utils.to_boolean(params.delete(:performance_bar_enabled))
      performance_bar_enabled = enable_param_on.nil? || enable_param_on # Default to true

      return if group_full_path.blank?
      return if enable_param_on == false # Explicitly disabling

      unless performance_bar_enabled
        application_setting.errors.add(:performance_bar_allowed_group_id, 'not allowed when performance bar is disabled')
        return
      end

      group = Group.find_by_full_path(group_full_path.chomp('/'))

      unless group
        application_setting.errors.add(:performance_bar_allowed_group_id, 'not found')
        return
      end

      group.id
    end

    def bypass_external_auth?
      params.key?(:external_authorization_service_enabled) && !Gitlab::Utils.to_boolean(params[:external_authorization_service_enabled])
    end
  end
end

ApplicationSettings::UpdateService.prepend_if_ee('EE::ApplicationSettings::UpdateService')
