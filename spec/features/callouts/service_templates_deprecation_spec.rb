# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service templates deprecation callout' do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_admin) { create(:user) }
  let_it_be(:callout_content) { 'Service templates are deprecated and will be removed in GitLab 14.0.' }

  context 'when a non-admin is logged in' do
    before do
      sign_in(non_admin)
      visit root_dashboard_path
    end

    it 'does not display callout' do
      expect(page).not_to have_content callout_content
    end
  end

  context 'when an admin is logged in' do
    before do
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)

      visit root_dashboard_path
    end

    context 'with no active service templates' do
      it 'does not display callout' do
        expect(page).not_to have_content callout_content
      end
    end

    context 'with active service template' do
      before do
        create(:service, :template, type: 'MattermostService', active: true)
        visit root_dashboard_path
      end

      it 'displays callout' do
        expect(page).to have_content callout_content
        expect(page).to have_link 'See affected service templates', href: admin_application_settings_services_path
      end

      context 'when callout is dismissed', :js do
        before do
          find('[data-testid="close-service-templates-deprecated-callout"]').click

          visit root_dashboard_path
        end

        it 'does not display callout' do
          expect(page).not_to have_content callout_content
        end
      end
    end
  end
end
