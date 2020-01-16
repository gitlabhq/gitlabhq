# frozen_string_literal: true

require 'spec_helper'

describe 'Project > Settings > CI/CD > Container registry tag expiration policy', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  context 'as owner' do
    before do
      sign_in(user)
      visit project_settings_ci_cd_path(project)
    end

    it 'section is available' do
      settings_block = find('#js-registry-policies')
      expect(settings_block).to have_text 'Container Registry tag expiration policy'
    end

    it 'Save expiration policy submit the form', :js do
      within '#js-registry-policies' do
        within '.card-body' do
          click_button(class: 'gl-toggle')
          select('7 days until tags are automatically removed', from: 'expiration-policy-interval')
          select('Every day', from: 'expiration-policy-schedule')
          select('50 tags per image name', from: 'expiration-policy-latest')
          fill_in('expiration-policy-name-matching', with: '*-production')
        end
        submit_button = find('.card-footer .btn.btn-success')
        expect(submit_button).not_to be_disabled
        submit_button.click
      end
      flash_text = find('.flash-text')
      expect(flash_text).to have_content('Expiration policy successfully saved.')
    end
  end
end
