# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environments page', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  before do
    project.add_role(user, role)
    sign_in(user)
  end

  def actions_button_selector
    '[data-testid="environment-actions-button"]'
  end

  def action_link_selector
    '[data-testid="manual-action-link"]'
  end

  def stop_button_selector
    'button[title="Stop environment"]'
  end

  def upcoming_deployment_content_selector
    '[data-testid="upcoming-deployment-content"]'
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
        it 'shows one environment' do
          visit_environments(project, scope: 'available')

          expect(page).to have_css('.environments-container')
          expect(page.all('.environment-name').length).to eq(1)
          expect(page.all('[data-testid="stop-icon"]').length).to eq(1)
        end
      end

      describe 'with environments spanning multiple pages', :js do
        before do
          allow(Kaminari.config).to receive(:default_per_page).and_return(3)
          create_list(:environment, 4, project: project, state: :available)
        end

        it 'renders second page of pipelines' do
          visit_environments(project, scope: 'available')

          find('.page-link.next-page-item').click
          wait_for_requests

          expect(page).to have_selector('.gl-pagination .page-link', count: 4)
          expect(find('.gl-pagination .page-link.active').text).to eq("2")
        end
      end

      describe 'in stopped tab page' do
        it 'shows no environments' do
          visit_environments(project, scope: 'stopped')

          expect(page).to have_css('.environments-container')
          expect(page).to have_content('You don\'t have any environments right now')
        end
      end

      context 'when cluster is not reachable' do
        let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
        let!(:integration_prometheus) { create(:clusters_integrations_prometheus, cluster: cluster) }

        before do
          allow_next_instance_of(Kubeclient::Client) do |instance|
            allow(instance).to receive(:proxy_url).and_raise(Kubeclient::HttpError.new(401, 'Unauthorized', nil))
          end
        end

        it 'shows one environment without error' do
          visit_environments(project, scope: 'available')

          expect(page).to have_css('.environments-container')
          expect(page.all('.environment-name').length).to eq(1)
        end
      end
    end

    describe 'with one stopped environment' do
      before do
        create(:environment, project: project, state: :stopped)
      end

      describe 'in available tab page' do
        it 'shows no environments' do
          visit_environments(project, scope: 'available')

          expect(page).to have_css('.environments-container')
          expect(page).to have_content('You don\'t have any environments right now')
        end
      end

      describe 'in stopped tab page' do
        it 'shows one environment' do
          visit_environments(project, scope: 'stopped')

          expect(page).to have_css('.environments-container')
          expect(page.all('.environment-name').length).to eq(1)
          expect(page.all('[data-testid="stop-icon"]').length).to eq(0)
        end
      end
    end
  end

  context 'without environments' do
    before do
      visit_environments(project)
    end

    it 'does not show environments and counters are set to zero' do
      expect(page).to have_content('You don\'t have any environments right now')

      expect(page.find('.js-environments-tab-available .badge').text).to eq('0')
      expect(page.find('.js-environments-tab-stopped .badge').text).to eq('0')
    end
  end

  describe 'environments table' do
    let!(:environment) do
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

      it 'shows stop button when environment is not stoppable' do
        expect(page).to have_selector(stop_button_selector)
      end
    end

    context 'when there are successful deployments' do
      let(:project) { create(:project, :repository) }

      let!(:deployment) do
        create(:deployment, :success,
                            environment: environment,
                            sha: project.commit.id)
      end

      it 'shows deployment SHA and internal ID' do
        visit_environments(project)

        expect(page).to have_link(deployment.short_sha)
        expect(page).to have_content(deployment.iid)
      end

      context 'when builds and manual actions are present' do
        let!(:pipeline) { create(:ci_pipeline, project: project) }
        let!(:build) { create(:ci_build, pipeline: pipeline) }

        let!(:action) do
          create(:ci_build, :manual, pipeline: pipeline, name: 'deploy to production')
        end

        let!(:deployment) do
          create(:deployment, :success,
                              environment: environment,
                              deployable: build,
                              sha: project.commit.id)
        end

        before do
          visit_environments(project)
        end

        it 'shows a play button' do
          find(actions_button_selector).click
          expect(page).to have_content(action.name)
        end

        it 'allows to play a manual action', :js do
          expect(action).to be_manual

          find(actions_button_selector).click
          expect(page).to have_content(action.name)

          expect { find(action_link_selector).click }
            .not_to change { Ci::Pipeline.count }
        end

        it 'shows build name and id' do
          expect(page).to have_link("#{build.name} ##{build.id}")
        end

        it 'shows a stop button' do
          expect(page).to have_selector(stop_button_selector)
        end

        it 'does not show external link button' do
          expect(page).not_to have_css('external-url')
        end

        it 'does not show terminal button' do
          expect(page).not_to have_terminal_button
        end

        context 'with external_url' do
          let(:environment) { create(:environment, project: project, external_url: 'https://git.gitlab.com') }
          let(:build) { create(:ci_build, pipeline: pipeline) }
          let(:deployment) { create(:deployment, :success, environment: environment, deployable: build) }

          it 'shows an external link button' do
            expect(page).to have_link(nil, href: environment.external_url)
          end
        end

        context 'with stop action' do
          let(:action) do
            create(:ci_build, :manual, pipeline: pipeline, name: 'close_app')
          end

          let(:deployment) do
            create(:deployment, :success,
                                environment: environment,
                                deployable: build,
                                on_stop: 'close_app')
          end

          it 'shows a stop button' do
            expect(page).to have_selector(stop_button_selector)
          end

          context 'when user is a reporter' do
            let(:role) { :reporter }

            it 'does not show stop button' do
              expect(page).not_to have_selector(stop_button_selector)
            end
          end
        end

        context 'when kubernetes terminal is available' do
          context 'when user configured kubernetes from CI/CD > Clusters' do
            let(:cluster) { create(:cluster, :provided_by_gcp, projects: [create(:project, :repository)]) }
            let(:project) { cluster.project }

            context 'for project maintainer' do
              let(:role) { :maintainer }

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
        end
      end

      context 'when there is a delayed job' do
        let!(:pipeline) { create(:ci_pipeline, project: project) }
        let!(:build) { create(:ci_build, pipeline: pipeline) }

        let!(:delayed_job) do
          create(:ci_build, :scheduled,
                 pipeline: pipeline,
                 name: 'delayed job',
                 stage: 'test')
        end

        let!(:deployment) do
          create(:deployment,
                 :success,
                 environment: environment,
                 deployable: build,
                 sha: project.commit.id)
        end

        before do
          visit_environments(project)
        end

        it 'has a dropdown for actionable jobs' do
          expect(page).to have_selector("#{actions_button_selector} [data-testid=\"play-icon\"]")
        end

        it "has link to the delayed job's action" do
          find(actions_button_selector).click

          expect(page).to have_button('delayed job')
          expect(page).to have_content(/\d{2}:\d{2}:\d{2}/)
        end

        context 'when delayed job is expired already' do
          let!(:delayed_job) do
            create(:ci_build, :expired_scheduled,
                   pipeline: pipeline,
                   name: 'delayed job',
                   stage: 'test')
          end

          it "shows 00:00:00 as the remaining time" do
            find(actions_button_selector).click

            expect(page).to have_content("00:00:00")
          end
        end

        context 'when user played a delayed job immediately' do
          before do
            find(actions_button_selector).click
            accept_confirm { find(action_link_selector).click }
            wait_for_requests
          end

          it 'enqueues the delayed job', :js do
            expect(delayed_job.reload).to be_pending
          end
        end
      end
    end

    context 'when there is a failed deployment' do
      let(:project) { create(:project, :repository) }

      let!(:deployment) do
        create(:deployment, :failed,
                            environment: environment,
                            sha: project.commit.id)
      end

      it 'does not show deployments' do
        visit_environments(project)

        expect(page).to have_content('No deployments yet')
      end
    end

    context 'when there is an upcoming deployment' do
      let_it_be(:project) { create(:project, :repository) }

      let!(:deployment) do
        create(:deployment, :running,
                            environment: environment,
                            sha: project.commit.id)
      end

      it "renders the upcoming deployment", :aggregate_failures do
        visit_environments(project)

        within(upcoming_deployment_content_selector) do
          expect(page).to have_content("##{deployment.iid}")
          expect(page).to have_selector("a[href=\"#{project_job_path(project, deployment.deployable)}\"]")
          expect(page).to have_link(href: /#{deployment.user.username}/)
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
      let(:role) { :developer }

      it 'developer creates a new environment with a valid name' do
        within(".environments-section") { click_link 'New environment' }
        fill_in('Name', with: 'production')
        click_on 'Save'

        expect(page).to have_content('production')
      end

      it 'developer creates a new environmetn with invalid name' do
        within(".environments-section") { click_link 'New environment' }
        fill_in('Name', with: 'name,with,commas')
        click_on 'Save'

        expect(page).to have_content('Name can contain only letters')
      end
    end

    context 'user is a reporter' do
      let(:role) { :reporter }

      it 'reporters tries to create a new environment' do
        expect(page).not_to have_link('New environment')
      end
    end
  end

  describe 'environments folders' do
    describe 'available environments' do
      before do
        create(:environment, :will_auto_stop,
                            project: project,
                            name: 'staging/review-1',
                            state: :available)
        create(:environment, :will_auto_stop,
                            project: project,
                            name: 'staging/review-2',
                            state: :available)
      end

      it 'users unfurls an environment folder' do
        visit_environments(project)

        expect(page).not_to have_content 'review-1'
        expect(page).not_to have_content 'review-2'
        expect(page).to have_content 'staging 2'

        within('.folder-row') do
          find('.folder-name', text: 'staging').click
        end

        expect(page).to have_content 'review-1'
        expect(page).to have_content 'review-2'
        within('.ci-table') do
          within('[data-qa-selector="environment_item"]', text: 'review-1') do
            expect(find('.js-auto-stop').text).not_to be_empty
          end
          within('[data-qa-selector="environment_item"]', text: 'review-2') do
            expect(find('.js-auto-stop').text).not_to be_empty
          end
        end
      end
    end

    describe 'stopped environments' do
      before do
        create(:environment, :will_auto_stop,
                            project: project,
                            name: 'staging/review-1',
                            state: :stopped)
        create(:environment, :will_auto_stop,
                            project: project,
                            name: 'staging/review-2',
                            state: :stopped)
      end

      it 'users unfurls an environment folder' do
        visit_environments(project, scope: 'stopped')

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

    it 'user opens folder view' do
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
