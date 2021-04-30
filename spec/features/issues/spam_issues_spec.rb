# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New issue', :js do
  include StubENV

  let(:project) { create(:project, :public) }
  let(:user)    { create(:user)}

  before do
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
  end

  context 'when SpamVerdictService disallows' do
    include_context 'includes Spam constants'

    before do
      allow_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
        allow(verdict_service).to receive(:execute).and_return(DISALLOW)
      end

      visit new_project_issue_path(project)
    end

    context 'when allow_possible_spam feature flag is false' do
      before do
        stub_feature_flags(allow_possible_spam: false)

        fill_in 'issue_title', with: 'issue title'
        fill_in 'issue_description', with: 'issue description'
      end

      it 'rejects issue creation' do
        click_button 'Create issue'

        expect(page).to have_content('discarded')
        expect(page).not_to have_content('potential spam')
        expect(page).not_to have_content('issue title')
      end

      it 'creates a spam log record' do
        expect { click_button 'Create issue' }
            .to log_spam(title: 'issue title', description: 'issue description', user_id: user.id, noteable_type: 'Issue')
      end
    end

    context 'when allow_possible_spam feature flag is true' do
      before do
        fill_in 'issue_title', with: 'issue title'
        fill_in 'issue_description', with: 'issue description'
      end

      it 'allows issue creation' do
        click_button 'Create issue'

        expect(page.find('.issue-details h2.title')).to have_content('issue title')
        expect(page.find('.issue-details .description')).to have_content('issue description')
      end

      it 'creates a spam log record' do
        expect { click_button 'Create issue' }
          .to log_spam(title: 'issue title', description: 'issue description', user_id: user.id, noteable_type: 'Issue')
      end
    end
  end

  context 'when SpamVerdictService requires recaptcha' do
    include_context 'includes Spam constants'

    before do
      allow_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
        allow(verdict_service).to receive(:execute).and_return(CONDITIONAL_ALLOW)
      end

      visit new_project_issue_path(project)
    end

    context 'when recaptcha is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
      end

      context 'when allow_possible_spam feature flag is false' do
        before do
          stub_feature_flags(allow_possible_spam: false)
        end

        it 'creates an issue after solving reCaptcha' do
          fill_in 'issue_title', with: 'issue title'
          fill_in 'issue_description', with: 'issue description'

          click_button 'Create issue'

          # it is impossible to test reCAPTCHA automatically and there is no possibility to fill in recaptcha
          # reCAPTCHA verification is skipped in test environment and it always returns true
          expect(page).not_to have_content('issue title')
          expect(page).to have_css('.recaptcha')

          click_button 'Create issue'

          expect(page.find('.issue-details h2.title')).to have_content('issue title')
          expect(page.find('.issue-details .description')).to have_content('issue description')
        end
      end

      context 'when allow_possible_spam feature flag is true' do
        before do
          fill_in 'issue_title', with: 'issue title'
          fill_in 'issue_description', with: 'issue description'
        end

        it 'creates an issue without a need to solve reCAPTCHA' do
          click_button 'Create issue'

          expect(page).not_to have_css('.recaptcha')
          expect(page.find('.issue-details h2.title')).to have_content('issue title')
          expect(page.find('.issue-details .description')).to have_content('issue description')
        end

        it 'creates a spam log record' do
          expect { click_button 'Create issue' }
              .to log_spam(title: 'issue title', description: 'issue description', user_id: user.id, noteable_type: 'Issue')
        end
      end
    end

    context 'when reCAPTCHA is not enabled' do
      before do
        stub_application_setting(recaptcha_enabled: false)
      end

      context 'when allow_possible_spam feature flag is true' do
        before do
          fill_in 'issue_title', with: 'issue title'
          fill_in 'issue_description', with: 'issue description'
        end

        it 'creates an issue without a need to solve reCaptcha' do
          click_button 'Create issue'

          expect(page).not_to have_css('.recaptcha')
          expect(page.find('.issue-details h2.title')).to have_content('issue title')
          expect(page.find('.issue-details .description')).to have_content('issue description')
        end

        it 'creates a spam log record' do
          expect { click_button 'Create issue' }
              .to log_spam(title: 'issue title', description: 'issue description', user_id: user.id, noteable_type: 'Issue')
        end
      end
    end
  end

  context 'when the SpamVerdictService allows' do
    include_context 'includes Spam constants'

    before do
      allow_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
        allow(verdict_service).to receive(:execute).and_return(ALLOW)
      end

      visit new_project_issue_path(project)
    end

    it 'creates an issue' do
      fill_in 'issue_title', with: 'issue title'
      fill_in 'issue_description', with: 'issue description'

      click_button 'Create issue'

      expect(page.find('.issue-details h2.title')).to have_content('issue title')
      expect(page.find('.issue-details .description')).to have_content('issue description')
    end
  end
end
