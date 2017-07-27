require 'spec_helper'

feature 'Environments page', :feature, :js do
  given(:project) { create(:empty_project) }
  given(:user) { create(:user) }
  given(:role) { :developer }

  background do
    project.team << [user, role]
    sign_in(user)
  end

  given!(:environment) { }
  given!(:deployment) { }
  given!(:action) { }

  before do
    visit_environments(project)
  end

  describe 'page tabs' do
    scenario 'shows "Available" and "Stopped" tab with links' do
      expect(page).to have_link('Available')
      expect(page).to have_link('Stopped')
    end

    describe 'with one available environment' do
      given(:environment) { create(:environment, project: project, state: :available) }

      describe 'in available tab page' do
        it 'should show one environment' do
          visit project_environments_path(project, scope: 'available')
          expect(page).to have_css('.environments-container')
          expect(page.all('.environment-name').length).to eq(1)
        end
      end

      describe 'in stopped tab page' do
        it 'should show no environments' do
          visit project_environments_path(project, scope: 'stopped')
          expect(page).to have_css('.environments-container')
          expect(page).to have_content('You don\'t have any environments right now')
        end
      end
    end

    describe 'with one stopped environment' do
      given(:environment) { create(:environment, project: project, state: :stopped) }

      describe 'in available tab page' do
        it 'should show no environments' do
          visit project_environments_path(project, scope: 'available')
          expect(page).to have_css('.environments-container')
          expect(page).to have_content('You don\'t have any environments right now')
        end
      end

      describe 'in stopped tab page' do
        it 'should show one environment' do
          visit project_environments_path(project, scope: 'stopped')
          expect(page).to have_css('.environments-container')
          expect(page.all('.environment-name').length).to eq(1)
        end
      end
    end
  end

  context 'without environments' do
    scenario 'does show no environments' do
      expect(page).to have_content('You don\'t have any environments right now.')
    end

    scenario 'does show 0 as counter for environments in both tabs' do
      expect(page.find('.js-available-environments-count').text).to eq('0')
      expect(page.find('.js-stopped-environments-count').text).to eq('0')
    end
  end

  describe 'when showing the environment' do
    given(:environment) { create(:environment, project: project) }

    scenario 'does show environment name' do
      expect(page).to have_link(environment.name)
    end

    scenario 'does show number of available and stopped environments' do
      expect(page.find('.js-available-environments-count').text).to eq('1')
      expect(page.find('.js-stopped-environments-count').text).to eq('0')
    end

    context 'without deployments' do
      scenario 'does show no deployments' do
        expect(page).to have_content('No deployments yet')
      end

      context 'for available environment' do
        given(:environment) { create(:environment, project: project, state: :available) }

        scenario 'does not shows stop button' do
          expect(page).not_to have_selector('.stop-env-link')
        end
      end

      context 'for stopped environment' do
        given(:environment) { create(:environment, project: project, state: :stopped) }

        scenario 'does not shows stop button' do
          expect(page).not_to have_selector('.stop-env-link')
        end
      end
    end

    context 'with deployments' do
      given(:project) { create(:project) }

      given(:deployment) do
        create(:deployment, environment: environment,
                            sha: project.commit.id)
      end

      scenario 'does show deployment SHA' do
        expect(page).to have_link(deployment.short_sha)
      end

      scenario 'does show deployment internal id' do
        expect(page).to have_content(deployment.iid)
      end

      context 'with build and manual actions' do
        given(:pipeline) { create(:ci_pipeline, project: project) }
        given(:build) { create(:ci_build, pipeline: pipeline) }

        given(:action) do
          create(:ci_build, :manual, pipeline: pipeline, name: 'deploy to production')
        end

        given(:deployment) do
          create(:deployment, environment: environment,
                              deployable: build,
                              sha: project.commit.id)
        end

        scenario 'does show a play button' do
          find('.js-dropdown-play-icon-container').click
          expect(page).to have_content(action.name.humanize)
        end

        scenario 'does allow to play manual action', js: true do
          expect(action).to be_manual

          find('.js-dropdown-play-icon-container').click
          expect(page).to have_content(action.name.humanize)

          expect { find('.js-manual-action-link').trigger('click') }
            .not_to change { Ci::Pipeline.count }
        end

        scenario 'does show build name and id' do
          expect(page).to have_link("#{build.name} ##{build.id}")
        end

        scenario 'does not show stop button' do
          expect(page).not_to have_selector('.stop-env-link')
        end

        scenario 'does not show external link button' do
          expect(page).not_to have_css('external-url')
        end

        scenario 'does not show terminal button' do
          expect(page).not_to have_terminal_button
        end

        context 'with external_url' do
          given(:environment) { create(:environment, project: project, external_url: 'https://git.gitlab.com') }
          given(:build) { create(:ci_build, pipeline: pipeline) }
          given(:deployment) { create(:deployment, environment: environment, deployable: build) }

          scenario 'does show an external link button' do
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

          scenario 'does show stop button' do
            expect(page).to have_selector('.stop-env-link')
          end

          context 'for reporter' do
            let(:role) { :reporter }

            scenario 'does not show stop button' do
              expect(page).not_to have_selector('.stop-env-link')
            end
          end
        end

        context 'with terminal' do
          let(:project) { create(:kubernetes_project, :test_repo) }

          context 'for project master' do
            let(:role) { :master }

            scenario 'it shows the terminal button' do
              expect(page).to have_terminal_button
            end
          end

          context 'for developer' do
            let(:role) { :developer }

            scenario 'does not show terminal button' do
              expect(page).not_to have_terminal_button
            end
          end
        end
      end
    end
  end

  scenario 'does have a New environment button' do
    expect(page).to have_link('New environment')
  end

  describe 'when creating a new environment' do
    before do
      visit_environments(project)
    end

    context 'when logged as developer' do
      before do
        within(".top-area") do
          click_link 'New environment'
        end
      end

      context 'for valid name' do
        before do
          fill_in('Name', with: 'production')
          click_on 'Save'
        end

        scenario 'does create a new pipeline' do
          expect(page).to have_content('production')
        end
      end

      context 'for invalid name' do
        before do
          fill_in('Name', with: 'name,with,commas')
          click_on 'Save'
        end

        scenario 'does show errors' do
          expect(page).to have_content('Name can contain only letters')
        end
      end
    end

    context 'when logged as reporter' do
      given(:role) { :reporter }

      scenario 'does not have a New environment link' do
        expect(page).not_to have_link('New environment')
      end
    end
  end

  def have_terminal_button
    have_link(nil, href: terminal_project_environment_path(project, environment))
  end

  def visit_environments(project)
    visit project_environments_path(project)
  end
end
