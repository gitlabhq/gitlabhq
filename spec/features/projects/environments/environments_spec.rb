require 'spec_helper'

feature 'Environments page', :js do
  given(:project) { create(:project) }
  given(:user) { create(:user) }
  given(:role) { :developer }

  background do
    project.add_role(user, role)
    sign_in(user)
  end

  describe 'page tabs' do
    it 'shows "Available" and "Stopped" tab with links' do
      visit_environments(project)

      expect(page).to have_selector('.js-environments-tab-available')
      expect(page).to have_content('Available')
      expect(page).to have_selector('.js-environments-tab-stopped')
      expect(page).to have_content('Stopped')
    end

    describe 'with one available environment' do
      before do
        create(:environment, project: project, state: :available)
      end

      describe 'in available tab page' do
        it 'should show one environment' do
          visit_environments(project, scope: 'available')

          expect(page).to have_css('.environments-container')
          expect(page.all('.environment-name').length).to eq(1)
        end
      end

      describe 'in stopped tab page' do
        it 'should show no environments' do
          visit_environments(project, scope: 'stopped')

          expect(page).to have_css('.environments-container')
          expect(page).to have_content('You don\'t have any environments right now')
        end
      end
    end

    describe 'with one stopped environment' do
      before do
        create(:environment, project: project, state: :stopped)
      end

      describe 'in available tab page' do
        it 'should show no environments' do
          visit_environments(project, scope: 'available')

          expect(page).to have_css('.environments-container')
          expect(page).to have_content('You don\'t have any environments right now')
        end
      end

      describe 'in stopped tab page' do
        it 'should show one environment' do
          visit_environments(project, scope: 'stopped')

          expect(page).to have_css('.environments-container')
          expect(page.all('.environment-name').length).to eq(1)
        end
      end
    end
  end

  context 'without environments' do
    before do
      visit_environments(project)
    end

    it 'does not show environments and counters are set to zero' do
      expect(page).to have_content('You don\'t have any environments right now.')

      expect(page.find('.js-environments-tab-available .badge').text).to eq('0')
      expect(page.find('.js-environments-tab-stopped .badge').text).to eq('0')
    end
  end

  describe 'environments table' do
    given!(:environment) do
      create(:environment, project: project, state: :available)
    end

    context 'when there are no deployments' do
      before do
        visit_environments(project)
      end

      it 'shows environments names and counters' do
        expect(page).to have_link(environment.name)

        expect(page.find('.js-environments-tab-available .badge').text).to eq('1')
        expect(page.find('.js-environments-tab-stopped .badge').text).to eq('0')
      end

      it 'does not show deployments' do
        expect(page).to have_content('No deployments yet')
      end

      it 'does not show stip button when environment is not stoppable' do
        expect(page).not_to have_selector('.stop-env-link')
      end
    end

    context 'when there are deployments' do
      given(:project) { create(:project, :repository) }

      given!(:deployment) do
        create(:deployment, environment: environment,
                            sha: project.commit.id)
      end

      it 'shows deployment SHA and internal ID' do
        visit_environments(project)

        expect(page).to have_link(deployment.short_sha)
        expect(page).to have_content(deployment.iid)
      end

      context 'when builds and manual actions are present' do
        given!(:pipeline) { create(:ci_pipeline, project: project) }
        given!(:build) { create(:ci_build, pipeline: pipeline) }

        given!(:action) do
          create(:ci_build, :manual, pipeline: pipeline, name: 'deploy to production')
        end

        given!(:deployment) do
          create(:deployment, environment: environment,
                              deployable: build,
                              sha: project.commit.id)
        end

        before do
          visit_environments(project)
        end

        it 'shows a play button' do
          find('.js-dropdown-play-icon-container').click

          expect(page).to have_content(action.name.humanize)
        end

        it 'allows to play a manual action', :js do
          expect(action).to be_manual

          find('.js-dropdown-play-icon-container').click
          expect(page).to have_content(action.name.humanize)

          expect { find('.js-manual-action-link').click }
            .not_to change { Ci::Pipeline.count }
        end

        it 'shows build name and id' do
          expect(page).to have_link("#{build.name} ##{build.id}")
        end

        it 'shows a stop button' do
          expect(page).not_to have_selector('.stop-env-link')
        end

        it 'does not show external link button' do
          expect(page).not_to have_css('external-url')
        end

        it 'does not show terminal button' do
          expect(page).not_to have_terminal_button
        end

        context 'with external_url' do
          given(:environment) { create(:environment, project: project, external_url: 'https://git.gitlab.com') }
          given(:build) { create(:ci_build, pipeline: pipeline) }
          given(:deployment) { create(:deployment, environment: environment, deployable: build) }

          it 'shows an external link button' do
            expect(page).to have_link(nil, href: environment.external_url)
          end
        end

        context 'with stop action' do
          given(:action) do
            create(:ci_build, :manual, pipeline: pipeline, name: 'close_app')
          end

          given(:deployment) do
            create(:deployment, environment: environment,
                                deployable: build,
                                on_stop: 'close_app')
          end

          it 'shows a stop button' do
            expect(page).to have_selector('.stop-env-link')
          end

          context 'when user is a reporter' do
            let(:role) { :reporter }

            it 'does not show stop button' do
              expect(page).not_to have_selector('.stop-env-link')
            end
          end
        end

        context 'when kubernetes terminal is available' do
          shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
            context 'for project master' do
              let(:role) { :master }

              it 'shows the terminal button' do
                expect(page).to have_terminal_button
              end
            end

            context 'when user is a developer' do
              let(:role) { :developer }

              it 'does not show terminal button' do
                expect(page).not_to have_terminal_button
              end
            end
          end

          context 'when user configured kubernetes from Integration > Kubernetes' do
            let(:project) { create(:kubernetes_project, :test_repo) }

            it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
          end

          context 'when user configured kubernetes from CI/CD > Clusters' do
            let(:cluster) { create(:cluster, :provided_by_gcp, projects: [create(:project, :repository)]) }
            let(:project) { cluster.project }

            it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
          end
        end
      end
    end
  end

  it 'does have a new environment button' do
    visit_environments(project)

    expect(page).to have_link('New environment')
  end

  describe 'creating a new environment' do
    before do
      visit_environments(project)
    end

    context 'user is a developer' do
      given(:role) { :developer }

      scenario 'developer creates a new environment with a valid name' do
        within(".top-area") { click_link 'New environment' }
        fill_in('Name', with: 'production')
        click_on 'Save'

        expect(page).to have_content('production')
      end

      scenario 'developer creates a new environmetn with invalid name' do
        within(".top-area") { click_link 'New environment' }
        fill_in('Name', with: 'name,with,commas')
        click_on 'Save'

        expect(page).to have_content('Name can contain only letters')
      end
    end

    context 'user is a reporter' do
      given(:role) { :reporter }

      scenario 'reporters tries to create a new environment' do
        expect(page).not_to have_link('New environment')
      end
    end
  end

  describe 'environments folders' do
    before do
      create(:environment, project: project,
                           name: 'staging/review-1',
                           state: :available)
      create(:environment, project: project,
                           name: 'staging/review-2',
                           state: :available)
    end

    scenario 'users unfurls an environment folder' do
      visit_environments(project)

      expect(page).not_to have_content 'review-1'
      expect(page).not_to have_content 'review-2'
      expect(page).to have_content 'staging 2'

      within('.folder-row') do
        find('.folder-name', text: 'staging').click
      end

      expect(page).to have_content 'review-1'
      expect(page).to have_content 'review-2'
    end
  end

  describe 'environments folders view' do
    before do
      create(:environment, project: project,
                           name: 'staging.review/review-1',
                           state: :available)
      create(:environment, project: project,
                           name: 'staging.review/review-2',
                           state: :available)
    end

    scenario 'user opens folder view' do
      visit folder_project_environments_path(project, 'staging.review')
      wait_for_requests

      expect(page).to have_content('Environments / staging.review')
      expect(page).to have_content('review-1')
      expect(page).to have_content('review-2')
    end
  end

  def have_terminal_button
    have_link(nil, href: terminal_project_environment_path(project, environment))
  end

  def visit_environments(project, **opts)
    visit project_environments_path(project, **opts)
    wait_for_requests
  end
end
