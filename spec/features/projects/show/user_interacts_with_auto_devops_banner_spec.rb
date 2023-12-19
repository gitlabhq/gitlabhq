# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Show > User interacts with auto devops implicitly enabled banner',
  feature_category: :auto_devops do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_member(user, role)
    sign_in(user)
  end

  context 'when user does not have maintainer access' do
    let(:role) { :developer }

    context 'when AutoDevOps is implicitly enabled' do
      it 'does not display AutoDevOps implicitly enabled banner' do
        expect(page).not_to have_css('.auto-devops-implicitly-enabled-banner')
      end
    end
  end

  context 'when user has mantainer access' do
    let(:role) { :maintainer }

    context 'when AutoDevOps is implicitly enabled' do
      before do
        stub_application_setting(auto_devops_enabled: true)

        visit project_path(project)
      end

      it 'display AutoDevOps implicitly enabled banner' do
        expect(page).to have_css('.auto-devops-implicitly-enabled-banner')
      end

      context 'when user dismisses the banner', :js do
        it 'does not display AutoDevOps implicitly enabled banner' do
          find('.hide-auto-devops-implicitly-enabled-banner').click
          wait_for_requests
          visit project_path(project)

          expect(page).not_to have_css('.auto-devops-implicitly-enabled-banner')
        end
      end
    end

    context 'when AutoDevOps is not implicitly enabled' do
      before do
        stub_application_setting(auto_devops_enabled: false)

        visit project_path(project)
      end

      it 'does not display AutoDevOps implicitly enabled banner' do
        expect(page).not_to have_css('.auto-devops-implicitly-enabled-banner')
      end
    end

    context 'when AutoDevOps enabled but container registry is disabled' do
      before do
        stub_application_setting(auto_devops_enabled: true)
        stub_container_registry_config(enabled: false)

        visit project_path(project)
      end

      it 'shows message that container registry is disabled' do
        expect(page).to have_content('Container registry is not enabled on this GitLab instance')
      end
    end
  end
end
