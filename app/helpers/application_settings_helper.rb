module ApplicationSettingsHelper
  def gravatar_enabled?
    current_application_settings.gravatar_enabled?
  end

  def twitter_sharing_enabled?
    current_application_settings.twitter_sharing_enabled?
  end

  def signup_enabled?
    current_application_settings.signup_enabled?
  end

  def signin_enabled?
    current_application_settings.signin_enabled?
  end

  def extra_sign_in_text
    current_application_settings.sign_in_text
  end

  def user_oauth_applications?
    current_application_settings.user_oauth_applications
  end

  def askimet_enabled?
    current_application_settings.akismet_enabled?
  end

  # Return a group of checkboxes that use Bootstrap's button plugin for a
  # toggle button effect.
  def restricted_level_checkboxes(help_block_id)
    Gitlab::VisibilityLevel.options.map do |name, level|
      checked = restricted_visibility_levels(true).include?(level)
      css_class = 'btn'
      css_class += ' active' if checked
      checkbox_name = 'application_setting[restricted_visibility_levels][]'

      label_tag(checkbox_name, class: css_class) do
        check_box_tag(checkbox_name, level, checked,
                      autocomplete: 'off',
                      'aria-describedby' => help_block_id) + name
      end
    end
  end

  # Return a group of checkboxes that use Bootstrap's button plugin for a
  # toggle button effect.
  def import_sources_checkboxes(help_block_id)
    Gitlab::ImportSources.options.map do |name, source|
      checked = current_application_settings.import_sources.include?(source)
      css_class = 'btn'
      css_class += ' active' if checked
      checkbox_name = 'application_setting[import_sources][]'

      label_tag(checkbox_name, class: css_class) do
        check_box_tag(checkbox_name, source, checked,
                      autocomplete: 'off',
                      'aria-describedby' => help_block_id) + name
      end
    end
  end
end
