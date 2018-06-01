module ApplicationSettings
  class UpdateService < ApplicationSettings::BaseService
    def execute
      # Repository size limit comes as MB from the view
      limit = @params.delete(:repository_size_limit)
      @application_setting.repository_size_limit = Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

      update_terms(@params.delete(:terms))

      if params.key?(:performance_bar_allowed_group_path)
        params[:performance_bar_allowed_group_id] = performance_bar_allowed_group_id
      end

      @application_setting.update(@params)
    end

    private

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
      return nil unless Gitlab::Utils.to_boolean(performance_bar_enabled)

      Group.find_by_full_path(group_full_path)&.id if group_full_path.present?
    end
  end
end
