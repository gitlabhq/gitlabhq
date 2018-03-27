require 'spec_helper'

feature 'Admin updates settings' do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
    visit admin_application_settings_path
  end

  scenario 'Change visibility settings' do
    page.within('.as-visibility-access') do
      choose "application_setting_default_project_visibility_20"
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
  end

  scenario 'Uncheck all restricted visibility levels' do
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

  scenario 'Change Visibility and Access Controls' do
    page.within('.as-visibility-access') do
      uncheck 'Project export enabled'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.project_export_enabled).to be_falsey
    expect(page).to have_content "Application settings saved successfully"
  end

  scenario 'Change Account and Limit Settings' do
    page.within('.as-account-limit') do
      uncheck 'Gravatar enabled'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.gravatar_enabled).to be_falsey
    expect(page).to have_content "Application settings saved successfully"
  end

  scenario 'Change Sign-in restrictions' do
    page.within('.as-signin') do
      fill_in 'Home page URL', with: 'https://about.gitlab.com/'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.home_page_url).to eq "https://about.gitlab.com/"
    expect(page).to have_content "Application settings saved successfully"
  end

  scenario 'Change Help page' do
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

  scenario 'Change Pages settings' do
    page.within('.as-pages') do
      fill_in 'Maximum size of pages (MB)', with: 15
      check 'Require users to prove ownership of custom domains'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.max_pages_size).to eq 15
    expect(Gitlab::CurrentSettings.pages_domain_verification_enabled?).to be_truthy
    expect(page).to have_content "Application settings saved successfully"
  end

  scenario 'Change AutoDevOps settings' do
    check 'Enabled Auto DevOps (Beta) for projects by default'
    fill_in 'Auto devops domain', with: 'domain.com'
    click_button 'Save'

    expect(Gitlab::CurrentSettings.auto_devops_enabled?).to be true
    expect(Gitlab::CurrentSettings.auto_devops_domain).to eq('domain.com')
    expect(page).to have_content "Application settings saved successfully"
  end

  scenario 'Change Slack Notifications Service template settings' do
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

  context 'sign-in restrictions', :js do
    it 'de-activates oauth sign-in source' do
      page.within('.as-signin') do
        find('input#application_setting_enabled_oauth_sign_in_sources_[value=gitlab]').send_keys(:return)

        expect(find('.btn', text: 'GitLab.com')).not_to have_css('.active')
      end
    end
  end

  scenario 'Change Keys settings' do
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

  scenario 'Change Performance Bar settings' do
    group = create(:group)

    check 'Enable the Performance Bar'
    fill_in 'Allowed group', with: group.path

    click_on 'Save'

    expect(page).to have_content 'Application settings saved successfully'

    expect(find_field('Enable the Performance Bar')).to be_checked
    expect(find_field('Allowed group').value).to eq group.path

    uncheck 'Enable the Performance Bar'

    click_on 'Save'

    expect(page).to have_content 'Application settings saved successfully'

    expect(find_field('Enable the Performance Bar')).not_to be_checked
    expect(find_field('Allowed group').value).to be_nil
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
