require 'spec_helper'

describe 'Auto deploy' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    create :kubernetes_service, project: project
    project.team << [user, :master]
    sign_in user
  end

  context 'when no deployment service is active' do
    before do
      project.kubernetes_service.update!(active: false)
    end

    it 'does not show a button to set up auto deploy' do
      visit project_path(project)
      expect(page).to have_no_content('Set up auto deploy')
    end
  end

  context 'when a deployment service is active' do
    before do
      project.kubernetes_service.update!(active: true)
      visit project_path(project)
    end

    it 'shows a button to set up auto deploy' do
      expect(page).to have_link('Set up auto deploy')
    end

    it 'includes OpenShift as an available template', js: true do
      click_link 'Set up auto deploy'
      click_button 'Apply a GitLab CI Yaml template'

      within '.gitlab-ci-yml-selector' do
        expect(page).to have_content('OpenShift')
      end
    end

    it 'creates a merge request using "auto-deploy" branch', js: true do
      click_link 'Set up auto deploy'
      click_button 'Apply a GitLab CI Yaml template'
      within '.gitlab-ci-yml-selector' do
        click_on 'OpenShift'
      end
      wait_for_requests
      click_button 'Commit changes'

      expect(page).to have_content('New Merge Request From auto-deploy into master')
    end
  end
end
