# frozen_string_literal: true

module PreferredLanguageSwitcher
  extend ActiveSupport::Concern

  private

  def init_preferred_language
    cookies[:preferred_language] = preferred_language
  end

  def preferred_language
    cookies[:preferred_language].presence_in(Gitlab::I18n.available_locales) ||
      Gitlab::CurrentSettings.default_preferred_language
  end
end

PreferredLanguageSwitcher.prepend_mod
