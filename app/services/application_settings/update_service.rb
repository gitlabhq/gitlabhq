module ApplicationSettings
  class UpdateService < ApplicationSettings::BaseService
    def execute
      # Repository size limit comes as MB from the view
      limit = @params.delete(:repository_size_limit)
      @application_setting.repository_size_limit = Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

      update_terms(@params.delete(:terms))

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
  end
end
