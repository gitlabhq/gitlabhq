# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Spam detection on issue creation', :js, feature_category: :team_planning do
  include Spec::Support::Helpers::ModalHelpers
  include StubENV

  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  include_context 'includes Spam constants'

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

    Gitlab::CurrentSettings.update!(
      akismet_enabled: true,
      akismet_api_key: 'testkey',
      spam_check_api_key: 'testkey',
      recaptcha_enabled: true,
      recaptcha_site_key: 'test site key',
      recaptcha_private_key: 'test private key'
    )

    project.add_maintainer(user)
    sign_in(user)
    visit new_project_issue_path(project)

    fill_in 'Title', with: 'issue title'
    fill_in 'Description', with: 'issue description'
  end

  shared_examples 'allows issue creation with CAPTCHA' do
    it 'allows issue creation' do
      find_button('Create issue').click # `click_button` would wait for the request to complete and would timeout with CAPTCHA being enabled

      # it is impossible to test reCAPTCHA automatically and there is no possibility to fill in recaptcha
      # so just confirm the reCAPTCHA modal appears
      within_modal do
        expect(page).to have_css('h2', text: 'Please solve the captcha')
        expect(page).to have_text('We want to be sure it is you, please confirm you are not a robot.')
      end
    end
  end

  shared_examples 'allows issue creation without CAPTCHA' do
    it 'allows issue creation without need to solve CAPTCHA' do
      click_button 'Create issue'

      expect(page).not_to have_css('.recaptcha')
      expect(page).to have_css('h1', text: 'issue title')
      within_testid('work-item-description') do
        expect(page).to have_text('issue description')
      end
    end
  end

  shared_context 'when spammable is identified as possible spam' do
    before do
      allow_next_instance_of(Spam::AkismetService) do |akismet_service|
        allow(akismet_service).to receive(:spam?).and_return(true)
      end
    end
  end

  shared_context 'when spammable is not identified as possible spam' do
    before do
      allow_next_instance_of(Spam::AkismetService) do |akismet_service|
        allow(akismet_service).to receive(:spam?).and_return(false)
      end
    end
  end

  shared_context 'when CAPTCHA is enabled' do
    before do
      stub_application_setting(recaptcha_enabled: true)
    end
  end

  shared_context 'when CAPTCHA is not enabled' do
    before do
      stub_application_setting(recaptcha_enabled: false)
    end
  end

  shared_context 'when allow_possible_spam application setting is true' do
    before do
      stub_application_setting(allow_possible_spam: true)
    end
  end

  shared_context 'when allow_possible_spam application setting is false' do
    before do
      stub_application_setting(allow_possible_spam: false)
    end
  end

  describe 'spam handling' do
    # verdict, spam_flagged, captcha_enabled, allow_possible_spam, creates_spam_log
    # TODO: Add example for BLOCK_USER verdict when we add support for testing SpamCheck - see https://gitlab.com/groups/gitlab-org/-/epics/5527#lacking-coverage-for-spamcheck-vs-akismet
    # DISALLOW, true, false, false, true
    # CONDITIONAL_ALLOW, true, true, false, true
    # OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM, true, true, true, true
    # OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM, true, false, true, true
    # ALLOW, false, true, false, false
    # TODO: Add example for NOOP verdict when we add support for testing SpamCheck - see https://gitlab.com/groups/gitlab-org/-/epics/5527#lacking-coverage-for-spamcheck-vs-akismet

    context 'DISALLOW: spam_flagged=true, captcha_enabled=true, allow_possible_spam=true' do
      include_context 'when spammable is identified as possible spam'
      include_context 'when CAPTCHA is enabled'
      include_context 'when allow_possible_spam application setting is true'

      it_behaves_like 'allows issue creation without CAPTCHA'
    end

    context 'CONDITIONAL_ALLOW: spam_flagged=true, captcha_enabled=true, allow_possible_spam=false' do
      include_context 'when spammable is identified as possible spam'
      include_context 'when CAPTCHA is enabled'
      include_context 'when allow_possible_spam application setting is false'

      it_behaves_like 'allows issue creation with CAPTCHA'
    end

    context 'OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM: spam_flagged=true, captcha_enabled=true, allow_possible_spam=true' do
      include_context 'when spammable is identified as possible spam'
      include_context 'when CAPTCHA is enabled'
      include_context 'when allow_possible_spam application setting is true'

      it_behaves_like 'allows issue creation without CAPTCHA'
    end

    context 'OVERRIDE_VIA_ALLOW_POSSIBLE_SPAM: spam_flagged=true, captcha_enabled=false, allow_possible_spam=true' do
      include_context 'when spammable is identified as possible spam'
      include_context 'when CAPTCHA is not enabled'
      include_context 'when allow_possible_spam application setting is true'

      it_behaves_like 'allows issue creation without CAPTCHA'
    end

    context 'ALLOW: spam_flagged=false, captcha_enabled=true, allow_possible_spam=false' do
      include_context 'when spammable is not identified as possible spam'
      include_context 'when CAPTCHA is not enabled'
      include_context 'when allow_possible_spam application setting is false'

      it_behaves_like 'allows issue creation without CAPTCHA'
    end
  end
end
