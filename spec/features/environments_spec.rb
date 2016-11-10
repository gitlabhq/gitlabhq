require 'spec_helper'

feature 'Environments', feature: true do
  given(:project) { create(:empty_project) }
  given(:user) { create(:user) }
  given(:role) { :developer }

  background do
    login_as(user)
    project.team << [user, role]
  end

  describe 'when showing environments' do
    given!(:environment) { }
    given!(:deployment) { }
    given!(:manual) { }

    before do
      visit namespace_project_environments_path(project.namespace, project)
    end

    context 'shows two tabs' do
      scenario 'shows "Available" and "Stopped" tab with links' do
        expect(page).to have_link('Available')
        expect(page).to have_link('Stopped')
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

    context 'with environments' do
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
      end

      context 'with deployments' do
        given(:deployment) { create(:deployment, environment: environment) }

        scenario 'does show deployment SHA' do
          expect(page).to have_link(deployment.short_sha)
        end

        scenario 'does show deployment internal id' do
          expect(page).to have_content(deployment.iid)
        end

        context 'with build and manual actions' do
          given(:pipeline) { create(:ci_pipeline, project: project) }
          given(:build) { create(:ci_build, pipeline: pipeline) }
          given(:deployment) { create(:deployment, environment: environment, deployable: build) }
          given(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'deploy to production') }

          scenario 'does show a play button' do
            expect(page).to have_link(manual.name.humanize)
          end

          scenario 'does allow to play manual action' do
            expect(manual).to be_skipped
            expect{ click_link(manual.name.humanize) }.not_to change { Ci::Pipeline.count }
            expect(page).to have_content(manual.name)
            expect(manual.reload).to be_pending
          end

          scenario 'does show build name and id' do
            expect(page).to have_link("#{build.name} (##{build.id})")
          end

          scenario 'does not show stop button' do
            expect(page).not_to have_selector('.stop-env-link')
          end

          scenario 'does not show external link button' do
            expect(page).not_to have_css('external-url')
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
            given(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'close_app') }
            given(:deployment) { create(:deployment, environment: environment, deployable: build, on_stop: 'close_app') }

            scenario 'does show stop button' do
              expect(page).to have_selector('.stop-env-link')
            end

            scenario 'starts build when stop button clicked' do
              first('.stop-env-link').click

              expect(page).to have_content('close_app')
            end

            context 'for reporter' do
              let(:role) { :reporter }

              scenario 'does not show stop button' do
                expect(page).not_to have_selector('.stop-env-link')
              end
            end
          end
        end
      end
    end

    scenario 'does have a New environment button' do
      expect(page).to have_link('New environment')
    end
  end

  describe 'when showing the environment' do
    given(:environment) { create(:environment, project: project) }
    given!(:deployment) { }
    given!(:manual) { }

    before do
      visit namespace_project_environment_path(project.namespace, project, environment)
    end

    context 'without deployments' do
      scenario 'does show no deployments' do
        expect(page).to have_content('You don\'t have any deployments right now.')
      end

      context 'for available environment' do
        given(:environment) { create(:environment, project: project, state: :available) }

        scenario 'does allow to stop environment' do
          click_link('Stop')

          expect(page).to have_content(environment.name.titleize)
        end
      end

      context 'for stopped environment' do
        given(:environment) { create(:environment, project: project, state: :stopped) }

        scenario 'does not shows stop button' do
          expect(page).not_to have_link('Stop')
        end
      end
    end

    context 'with deployments' do
      given(:deployment) { create(:deployment, environment: environment) }

      scenario 'does show deployment SHA' do
        expect(page).to have_link(deployment.short_sha)
      end

      scenario 'does not show a re-deploy button for deployment without build' do
        expect(page).not_to have_link('Re-deploy')
      end

      context 'with build' do
        given(:pipeline) { create(:ci_pipeline, project: project) }
        given(:build) { create(:ci_build, pipeline: pipeline) }
        given(:deployment) { create(:deployment, environment: environment, deployable: build) }

        scenario 'does show build name' do
          expect(page).to have_link("#{build.name} (##{build.id})")
        end

        scenario 'does show re-deploy button' do
          expect(page).to have_link('Re-deploy')
        end

        context 'with manual action' do
          given(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'deploy to production') }

          scenario 'does show a play button' do
            expect(page).to have_link(manual.name.humanize)
          end

          scenario 'does allow to play manual action' do
            expect(manual).to be_skipped
            expect{ click_link(manual.name.humanize) }.not_to change { Ci::Pipeline.count }
            expect(page).to have_content(manual.name)
            expect(manual.reload).to be_pending
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
            given(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'close_app') }
            given(:deployment) { create(:deployment, environment: environment, deployable: build, on_stop: 'close_app') }

            scenario 'does show stop button' do
              expect(page).to have_link('Stop')
            end

            scenario 'does allow to stop environment' do
              click_link('Stop')

              expect(page).to have_content('close_app')
            end

            context 'for reporter' do
              let(:role) { :reporter }

              scenario 'does not show stop button' do
                expect(page).not_to have_link('Stop')
              end
            end
          end
        end
      end
    end
  end

  describe 'when creating a new environment' do
    before do
      visit namespace_project_environments_path(project.namespace, project)
    end

    context 'when logged as developer' do
      before do
        click_link 'New environment'
      end

      context 'for valid name' do
        before do
          fill_in('Name', with: 'production')
          click_on 'Save'
        end

        scenario 'does create a new pipeline' do
          expect(page).to have_content('Production')
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
end
