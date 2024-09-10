# frozen_string_literal: true

module PreferredLanguageSwitcher
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize
  include PreferredLanguageSwitcherHelper

  private

  def init_preferred_language
    return if Feature.enabled?(:disable_preferred_language_cookie)

    cookies[:preferred_language] = preferred_language
  end

  def preferred_language
    cookies[:preferred_language].presence_in(Gitlab::I18n.available_locales) ||
      selectable_language(marketing_site_language) ||
      selectable_language(browser_languages) ||
      Gitlab::CurrentSettings.default_preferred_language
  end

  def selectable_language(language_options)
    language_options.find { |lan| ordered_selectable_locales_codes.include?(lan) }
  end

  def ordered_selectable_locales_codes
    ordered_selectable_locales.pluck(:value) # rubocop:disable CodeReuse/ActiveRecord
  end

  def browser_languages
    formatted_http_language_header = request.env['HTTP_ACCEPT_LANGUAGE']&.tr('-', '_')

    return [] unless formatted_http_language_header

    formatted_http_language_header.split(%r{[;,]}).reject { |str| str.start_with?('q') }
  end
  strong_memoize_attr :browser_languages

  def marketing_site_language
    # Our marketing site will be the only thing we are sure of the language placement in the url for.
    locale = params[:glm_source]&.match(%r{\A#{ApplicationHelper.promo_host}/([a-z]{2})-([a-z]{2})}i)&.captures

    return [] if locale.blank?

    # This is local and then locale_region - the marketing site will always send locale-region pairs like fr-fr.
    [locale[0], "#{locale[0]}_#{locale[1]}"]
  end
end

PreferredLanguageSwitcher.prepend_mod
