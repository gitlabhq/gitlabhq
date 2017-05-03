require 'spec_helper'

describe 'Auto deploy' do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.create_kubernetes_service(
      active: true,
      properties: {
        namespace: project.path,
        api_url: 'https://kubernetes.example.com',
        token: 'a' * 40,
      }
    )
    project.team << [user, :master]
    login_as user
  end

  context 'when no deployment service is active' do
    before do
      project.kubernetes_service.update!(active: false)
    end

    it 'does not show a button to set up auto deploy' do
      visit namespace_project_path(project.namespace, project)
      expect(page).to have_no_content('Set up auto deploy')
    end
  end

  context 'when a deployment service is active' do
    before do
      project.kubernetes_service.update!(active: true)
      visit namespace_project_path(project.namespace, project)
    end

    it 'shows a button to set up auto deploy' do
      expect(page).to have_link('Set up auto deploy')
    end

    it 'includes OpenShift as an available template', js: true do
      click_link 'Set up auto deploy'
      click_button 'Choose a GitLab CI Yaml template'

      within '.gitlab-ci-yml-selector' do
        expect(page).to have_content('OpenShift')
      end
    end

    it 'creates a merge request using "auto-deploy" branch', js: true do
      click_link 'Set up auto deploy'
      click_button 'Choose a GitLab CI Yaml template'
      within '.gitlab-ci-yml-selector' do
        click_on 'OpenShift'
      end
      wait_for_ajax
      click_button 'Commit Changes'

      expect(page).to have_content('New Merge Request From auto-deploy into master')
    end
  end
end
