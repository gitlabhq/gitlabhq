require 'spec_helper'

describe 'Auto deploy' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
    context 'when no deployment service is active' do
      before do
        trun_off
      end

      it 'does not show a button to set up auto deploy' do
        visit project_path(project)
        expect(page).to have_no_content('Set up auto deploy')
      end
    end

    context 'when a deployment service is active' do
      before do
        trun_on
        visit project_path(project)
      end

      it 'shows a button to set up auto deploy' do
        expect(page).to have_link('Set up auto deploy')
      end

      it 'includes OpenShift as an available template', :js do
        click_link 'Set up auto deploy'
        click_button 'Apply a GitLab CI Yaml template'

        within '.gitlab-ci-yml-selector' do
          expect(page).to have_content('OpenShift')
        end
      end

      it 'creates a merge request using "auto-deploy" branch', :js do
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

  context 'when user configured kubernetes from Integration > Kubernetes' do
    before do
      create :kubernetes_service, project: project
      project.add_master(user)
      sign_in user
    end

    let(:trun_on) { project.deployment_platform.update!(active: true) }
    let(:trun_off) { project.deployment_platform.update!(active: false) }

    it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
  end

  context 'when user configured kubernetes from CI/CD > Clusters' do
    before do
      create(:cluster, :provided_by_gcp, projects: [project])
      project.add_master(user)
      sign_in user
    end

    let(:trun_on) { project.deployment_platform.cluster.update!(enabled: true) }
    let(:trun_off) { project.deployment_platform.cluster.update!(enabled: false) }

    it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
  end
end
