require 'spec_helper'

describe 'Environments' do
  include GitlabRoutingHelper

  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  before do
    login_as(user)
    project.team << [user, role]
  end

  describe 'GET /:project/environments' do
    subject { visit namespace_project_environments_path(project.namespace, project) }

    context 'without environments' do
      it 'does show no environments' do
        subject

        expect(page).to have_content('No environments to show')
      end
    end

    context 'with environments' do
      let!(:environment) { create(:environment, project: project) }

      it 'does show environment name' do
        subject

        expect(page).to have_link(environment.name)
      end

      context 'without deployments' do
        it 'does show no deployments' do
          subject

          expect(page).to have_content('No deployments yet')
        end
      end

      context 'with deployments' do
        let!(:deployment) { create(:deployment, environment: environment) }

        it 'does show deployment SHA' do
          subject

          expect(page).to have_link(deployment.short_sha)
        end
      end
    end

    it 'does have a New environment button' do
      subject

      expect(page).to have_link('New environment')
    end
  end

  describe 'GET /:project/environments/:id' do
    let(:environment) { create(:environment, project: project) }

    subject { visit namespace_project_environment_path(project.namespace, project, environment) }

    context 'without deployments' do
      it 'does show no deployments' do
        subject

        expect(page).to have_content('No deployments for')
      end
    end

    context 'with deployments' do
      let!(:deployment) { create(:deployment, environment: environment) }

      before { subject }

      it 'does show deployment SHA' do
        expect(page).to have_link(deployment.short_sha)
      end

      it 'does not show a retry button for deployment without build' do
        expect(page).not_to have_link('Retry')
      end

      context 'with build' do
        let(:build) { create(:ci_build, project: project) }
        let(:deployment) { create(:deployment, environment: environment, deployable: build) }

        it 'does show build name' do
          expect(page).to have_link("#{build.name} (##{build.id})")
        end

        it 'does show retry button' do
          expect(page).to have_link('Retry')
        end
      end
    end
  end

  describe 'POST /:project/environments' do
    before { visit namespace_project_environments_path(project.namespace, project) }

    context 'when logged as developer' do
      before { click_link 'New environment' }

      context 'for valid name' do
        before do
          fill_in('Name', with: 'production')
          click_on 'Create environment'
        end

        it 'does create a new pipeline' do
          expect(page).to have_content('production')
        end
      end

      context 'for invalid name' do
        before do
          fill_in('Name', with: 'name with spaces')
          click_on 'Create environment'
        end

        it { expect(page).to have_content('Name can contain only letters') }
      end
    end

    context 'when logged as reporter' do
      let(:role) { :reporter }

      it 'does not have a New environment link' do
        expect(page).not_to have_link('New environment')
      end
    end
  end

  describe 'DELETE /:project/environments/:id' do
    let(:environment) { create(:environment, project: project) }

    before { visit namespace_project_environment_path(project.namespace, project, environment) }

    context 'when logged as master' do
      let(:role) { :master }

      before { click_link 'Destroy' }

      it 'does not have environment' do
        expect(page).not_to have_link(environment.name)
      end
    end

    context 'when logged as developer' do
      let(:role) { :developer }

      it 'does not have a Destroy link' do
        expect(page).not_to have_link('Destroy')
      end
    end
  end
end
