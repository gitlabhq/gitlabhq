module ApplicationSettingsHelper
  def gravatar_enabled?
    current_application_settings.gravatar_enabled?
  end

  def signup_enabled?
    current_application_settings.signup_enabled?
  end

  def signin_enabled?
    current_application_settings.signin_enabled?
  end

  def user_oauth_applications?
    current_application_settings.user_oauth_applications
  end

  def askimet_enabled?
    current_application_settings.akismet_enabled?
  end

  def koding_enabled?
    current_application_settings.koding_enabled?
  end

  def allowed_protocols_present?
    current_application_settings.enabled_git_access_protocol.present?
  end

  def enabled_protocol
    case current_application_settings.enabled_git_access_protocol
    when 'http'
      gitlab_config.protocol
    when 'ssh'
      'ssh'
    end
  end

  def enabled_project_button(project, protocol)
    case protocol
    when 'ssh'
      ssh_clone_button(project, 'bottom', append_link: false)
    else
      http_clone_button(project, 'bottom', append_link: false)
    end
  end

  # Return a group of checkboxes that use Bootstrap's button plugin for a
  # toggle button effect.
  def restricted_level_checkboxes(help_block_id)
    Gitlab::VisibilityLevel.options.map do |name, level|
      checked = restricted_visibility_levels(true).include?(level)
      css_class = checked ? 'active' : ''
      checkbox_name = "application_setting[restricted_visibility_levels][]"

      label_tag(name, class: css_class) do
        check_box_tag(checkbox_name, level, checked,
                      autocomplete: 'off',
                      'aria-describedby' => help_block_id,
                      id: name) + visibility_level_icon(level) + name
      end
    end
  end

  # Return a group of checkboxes that use Bootstrap's button plugin for a
  # toggle button effect.
  def import_sources_checkboxes(help_block_id)
    Gitlab::ImportSources.options.map do |name, source|
      checked = current_application_settings.import_sources.include?(source)
      css_class = checked ? 'active' : ''
      checkbox_name = 'application_setting[import_sources][]'

      label_tag(name, class: css_class) do
        check_box_tag(checkbox_name, source, checked,
                      autocomplete: 'off',
                      'aria-describedby' => help_block_id,
                      id: name.tr(' ', '_')) + name
      end
    end
  end

  def oauth_providers_checkboxes
    button_based_providers.map do |source|
      disabled = current_application_settings.disabled_oauth_sign_in_sources.include?(source.to_s)
      css_class = 'btn'
      css_class << ' active' unless disabled
      checkbox_name = 'application_setting[enabled_oauth_sign_in_sources][]'

      label_tag(checkbox_name, class: css_class) do
        check_box_tag(checkbox_name, source, !disabled,
                      autocomplete: 'off') + Gitlab::OAuth::Provider.label_for(source)
      end
    end
  end

  def repository_storages_options_for_select
    options = Gitlab.config.repositories.storages.map do |name, path|
      ["#{name} - #{path}", name]
    end

    options_for_select(options, @application_setting.repository_storages)
  end

  def sidekiq_queue_options_for_select
    options_for_select(Sidekiq::Queue.all.map(&:name), @application_setting.sidekiq_throttling_queues)
  end
end
