module ApplicationSettings
  class UpdateService < ApplicationSettings::BaseService
    def execute
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
