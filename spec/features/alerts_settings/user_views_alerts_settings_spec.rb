# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Alert integrations settings form', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }

  before_all do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
  end

  before do
    sign_in(maintainer)
  end

  describe 'when viewing alert integrations as a maintainer' do
    context 'with the default page permissions' do
      before do
        visit project_settings_operations_path(project, anchor: 'js-alert-management-settings')
        wait_for_requests
      end

      it 'shows the alerts setting form title' do
        page.within('#js-alert-management-settings') do
          expect(find('h4')).to have_content('Alerts')
        end
      end

      it 'shows the integrations list title' do
        expect(page).to have_content('Current integrations')
      end
    end
  end

  describe 'when viewing alert integrations as a developer' do
    before do
      sign_in(developer)

      visit project_settings_operations_path(project, anchor: 'js-alert-management-settings')
      wait_for_requests
    end

    it 'does not have rights to access the setting form' do
      expect(page).not_to have_selector('.incident-management-list')
      expect(page).not_to have_selector('#js-alert-management-settings')
    end
  end
end
