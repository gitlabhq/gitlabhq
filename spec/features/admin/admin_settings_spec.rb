require 'spec_helper'

describe 'Admin updates settings' do
  include StubENV
  include TermsHelper

  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
  end

  it 'Change visibility settings' do
    visit admin_application_settings_path

    page.within('.as-visibility-access') do
      choose "application_setting_default_project_visibility_20"
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Uncheck all restricted visibility levels' do
    visit admin_application_settings_path

    page.within('.as-visibility-access') do
      find('#application_setting_visibility_level_0').set(false)
      find('#application_setting_visibility_level_10').set(false)
      find('#application_setting_visibility_level_20').set(false)
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(find('#application_setting_visibility_level_0')).not_to be_checked
    expect(find('#application_setting_visibility_level_10')).not_to be_checked
    expect(find('#application_setting_visibility_level_20')).not_to be_checked
  end

  it 'Modify import sources' do
    visit admin_application_settings_path

    expect(Gitlab::CurrentSettings.import_sources).not_to be_empty

    page.within('.as-visibility-access') do
      Gitlab::ImportSources.options.map do |name, _|
        uncheck name
      end

      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.import_sources).to be_empty

    page.within('.as-visibility-access') do
      check "Repo by URL"
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.import_sources).to eq(['git'])
  end

  it 'Change Visibility and Access Controls' do
    visit admin_application_settings_path

    page.within('.as-visibility-access') do
      uncheck 'Project export enabled'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.project_export_enabled).to be_falsey
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Change Account and Limit Settings' do
    visit admin_application_settings_path

    page.within('.as-account-limit') do
      uncheck 'Gravatar enabled'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.gravatar_enabled).to be_falsey
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Change New users set to external', :js do
    visit admin_application_settings_path

    user_internal_regex = find('#application_setting_user_default_internal_regex', visible: :all)

    expect(user_internal_regex).to be_readonly
    expect(user_internal_regex['placeholder']).to eq 'To define internal users, first enable new users set to external'

    check 'application_setting_user_default_external'

    expect(user_internal_regex).not_to be_readonly
    expect(user_internal_regex['placeholder']).to eq 'Regex pattern'
  end

  it 'Change Sign-in restrictions' do
    visit admin_application_settings_path

    page.within('.as-signin') do
      fill_in 'Home page URL', with: 'https://about.gitlab.com/'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.home_page_url).to eq "https://about.gitlab.com/"
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Terms of Service' do
    visit admin_application_settings_path

    # Already have the admin accept terms, so they don't need to accept in this spec.
    _existing_terms = create(:term)
    accept_terms(admin)

    page.within('.as-terms') do
      check 'Require all users to accept Terms of Service and Privacy Policy when they access GitLab.'
      fill_in 'Terms of Service Agreement', with: 'Be nice!'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.enforce_terms).to be(true)
    expect(Gitlab::CurrentSettings.terms).to eq 'Be nice!'
    expect(page).to have_content 'Application settings saved successfully'
  end

  it 'Modify oauth providers' do
    visit admin_application_settings_path

    expect(Gitlab::CurrentSettings.disabled_oauth_sign_in_sources).to be_empty

    page.within('.as-signin') do
      uncheck 'Google'
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.disabled_oauth_sign_in_sources).to include('google_oauth2')

    page.within('.as-signin') do
      check "Google"
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.disabled_oauth_sign_in_sources).not_to include('google_oauth2')
  end

  it 'Oauth providers do not raise validation errors when saving unrelated changes' do
    visit admin_application_settings_path

    expect(Gitlab::CurrentSettings.disabled_oauth_sign_in_sources).to be_empty

    page.within('.as-signin') do
      uncheck 'Google'
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.disabled_oauth_sign_in_sources).to include('google_oauth2')

    # Remove google_oauth2 from the Omniauth strategies
    allow(Devise).to receive(:omniauth_providers).and_return([])

    # Save an unrelated setting
    page.within('.as-terms') do
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.disabled_oauth_sign_in_sources).to include('google_oauth2')
  end

  it 'Change Help page' do
    visit preferences_admin_application_settings_path

    page.within('.as-help-page') do
      fill_in 'Help page text', with: 'Example text'
      check 'Hide marketing-related entries from help'
      fill_in 'Support page URL', with: 'http://example.com/help'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.help_page_text).to eq "Example text"
    expect(Gitlab::CurrentSettings.help_page_hide_commercial_content).to be_truthy
    expect(Gitlab::CurrentSettings.help_page_support_url).to eq "http://example.com/help"
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Change Pages settings' do
    visit preferences_admin_application_settings_path

    page.within('.as-pages') do
      fill_in 'Maximum size of pages (MB)', with: 15
      check 'Require users to prove ownership of custom domains'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.max_pages_size).to eq 15
    expect(Gitlab::CurrentSettings.pages_domain_verification_enabled?).to be_truthy
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Change CI/CD settings' do
    visit ci_cd_admin_application_settings_path

    page.within('.as-ci-cd') do
      check 'Default to Auto DevOps pipeline for all projects'
      fill_in 'Auto devops domain', with: 'domain.com'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.auto_devops_enabled?).to be true
    expect(Gitlab::CurrentSettings.auto_devops_domain).to eq('domain.com')
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Change Influx settings' do
    visit metrics_and_profiling_admin_application_settings_path

    page.within('.as-influx') do
      check 'Enable InfluxDB Metrics'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.metrics_enabled?).to be true
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Change Prometheus settings' do
    visit metrics_and_profiling_admin_application_settings_path

    page.within('.as-prometheus') do
      check 'Enable Prometheus Metrics'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.prometheus_metrics_enabled?).to be true
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Change Performance bar settings' do
    visit metrics_and_profiling_admin_application_settings_path

    group = create(:group)

    page.within('.as-performance-bar') do
      check 'Enable the Performance Bar'
      fill_in 'Allowed group', with: group.path
      click_on 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(find_field('Enable the Performance Bar')).to be_checked
    expect(find_field('Allowed group').value).to eq group.path

    page.within('.as-performance-bar') do
      uncheck 'Enable the Performance Bar'
      click_on 'Save changes'
    end

    expect(page).to have_content 'Application settings saved successfully'
    expect(find_field('Enable the Performance Bar')).not_to be_checked
    expect(find_field('Allowed group').value).to be_nil
  end

  it 'Change Background jobs settings' do
    visit preferences_admin_application_settings_path

    page.within('.as-background') do
      fill_in 'Throttling Factor', with: 1
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.sidekiq_throttling_factor).to eq(1)
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Change Spam settings' do
    visit reporting_admin_application_settings_path

    page.within('.as-spam') do
      check 'Enable reCAPTCHA'
      fill_in 'reCAPTCHA Site Key', with: 'key'
      fill_in 'reCAPTCHA Private Key', with: 'key'
      fill_in 'IPs per user', with: 15
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.recaptcha_enabled).to be true
    expect(Gitlab::CurrentSettings.unique_ips_limit_per_user).to eq(15)
  end

  it 'Configure web terminal' do
    visit admin_application_settings_path

    page.within('.as-terminal') do
      fill_in 'Max session time', with: 15
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.terminal_max_session_time).to eq(15)
  end

  it 'Enable outbound requests' do
    visit network_admin_application_settings_path

    page.within('.as-outbound') do
      check 'Allow requests to the local network from hooks and services'
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.allow_local_requests_from_hooks_and_services).to be true
  end

  it 'Enable hiding third party offers' do
    visit integrations_admin_application_settings_path

    page.within('.as-third-party-offers') do
      check 'Do not display offers from third parties within GitLab'
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
    expect(Gitlab::CurrentSettings.hide_third_party_offers).to be true
  end

  it 'Change Slack Notifications Service template settings' do
    visit integrations_admin_application_settings_path

    first(:link, 'Service Templates').click
    click_link 'Slack notifications'
    fill_in 'Webhook', with: 'http://localhost'
    fill_in 'Username', with: 'test_user'
    fill_in 'service_push_channel', with: '#test_channel'
    page.check('Notify only broken pipelines')
    page.check('Notify only default branch')

    check_all_events
    click_on 'Save'

    expect(page).to have_content 'Application settings saved successfully'

    click_link 'Slack notifications'

    page.all('input[type=checkbox]').each do |checkbox|
      expect(checkbox).to be_checked
    end
    expect(find_field('Webhook').value).to eq 'http://localhost'
    expect(find_field('Username').value).to eq 'test_user'
    expect(find('#service_push_channel').value).to eq '#test_channel'
  end

  it 'Change Keys settings' do
    visit admin_application_settings_path

    page.within('.as-visibility-access') do
      select 'Are forbidden', from: 'RSA SSH keys'
      select 'Are allowed', from: 'DSA SSH keys'
      select 'Must be at least 384 bits', from: 'ECDSA SSH keys'
      select 'Are forbidden', from: 'ED25519 SSH keys'
      click_on 'Save changes'
    end

    forbidden = ApplicationSetting::FORBIDDEN_KEY_VALUE.to_s

    expect(page).to have_content 'Application settings saved successfully'
    expect(find_field('RSA SSH keys').value).to eq(forbidden)
    expect(find_field('DSA SSH keys').value).to eq('0')
    expect(find_field('ECDSA SSH keys').value).to eq('384')
    expect(find_field('ED25519 SSH keys').value).to eq(forbidden)
  end

  it 'loads usage ping payload on click', :js do
    expect(page).to have_button 'Preview payload'

    find('.js-usage-ping-payload-trigger').click

    expect(page).to have_selector '.js-usage-ping-payload'
    expect(page).to have_button 'Hide payload'
  end

  def check_all_events
    page.check('Active')
    page.check('Push')
    page.check('Tag push')
    page.check('Note')
    page.check('Issue')
    page.check('Merge request')
    page.check('Pipeline')
  end
end
