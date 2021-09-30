# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Security newsletter callout', :js do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_admin) { create(:user) }

  shared_examples 'hidden callout' do
    it 'does not display callout' do
      expect(page).not_to have_content 'Sign up for the GitLab Security Newsletter to get notified for security updates.'
    end
  end

  context 'when an admin is logged in' do
    before do
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)

      visit admin_root_path
    end

    it 'displays callout' do
      expect(page).to have_content 'Sign up for the GitLab Security Newsletter to get notified for security updates.'
      expect(page).to have_link 'Sign up for the GitLab newsletter', href: 'https://about.gitlab.com/company/preference-center/'
    end

    context 'when link is clicked' do
      before do
        find_link('Sign up for the GitLab newsletter').click

        visit admin_root_path
      end

      it_behaves_like 'hidden callout'
    end

    context 'when callout is dismissed' do
      before do
        find('[data-testid="close-security-newsletter-callout"]').click

        visit admin_root_path
      end

      it_behaves_like 'hidden callout'
    end
  end

  context 'when a non-admin is logged in' do
    before do
      sign_in(non_admin)
      visit admin_root_path
    end

    it_behaves_like 'hidden callout'
  end
end
