# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Integration settings', feature_category: :integrations do
  context 'when the integration is for a project ' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    context 'with Zentao integration records' do
      before do
        create(:integration, project: project, type_new: 'Integrations::Zentao', category: 'issue_tracker')
      end

      it 'shows settings without Zentao', :js do
        visit namespace_project_settings_integrations_path(namespace_id: project.namespace.full_path,
          project_id: project.path)

        expect(page).to have_content('Add an integration')
        expect(page).not_to have_content('ZenTao')
      end
    end
  end

  context 'when the integration is for the instance' do
    let_it_be(:user) { create(:admin) }

    before do
      sign_in(user)
      enable_admin_mode!(user)
    end

    context 'with Beyond Identity', :js do
      it 'creates a Beyond Identity integration' do
        visit edit_admin_application_settings_integration_path(Integrations::BeyondIdentity.to_param)

        first('label', text: 'Exclude service accounts').click
        fill_in('service-token', with: 'sometoken')

        click_button 'Save changes'
        click_button 'Save'

        expect(page).to have_checked_field('Active')
        expect(page).to have_checked_field('Exclude service accounts')

        integration = Integrations::BeyondIdentity.for_instance.take
        expect(integration).to be_active
        expect(integration.exclude_service_accounts).to be_truthy
      end
    end
  end
end
