# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environments page', :js, feature_category: :continuous_delivery do
  include Spec::Support::Helpers::ModalHelpers

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
    describe 'with one available environment' do
      let!(:environment) { create(:environment, project: project, state: :available) }

      it 'shows "Active" and "Stopped" tab with links' do
        visit_environments(project)

        expect(page).to have_link(_('Active'))
        expect(page).to have_link(_('Stopped'))
      end

      describe 'in active tab page' do
        it 'shows one environment' do
          visit_environments(project, scope: 'active')

          expect(page).to have_link(environment.name, href: project_environment_path(project, environment))
        end
      end

      describe 'with environments spanning multiple pages', :js do
        before do
          allow(Kaminari.config).to receive(:default_per_page).and_return(3)
          create_list(:environment, 4, project: project, state: :available)
        end

        it 'renders second page of pipelines' do
          visit_environments(project, scope: 'active')

          find_by_testid('gl-pagination-next').click
          wait_for_requests

          expect(page).to have_selector('[data-testid="gl-pagination-li"]', count: 4)
          expect(find('[data-testid="gl-pagination-item"].active').text).to eq("2")
        end
      end

      describe 'in stopped tab page' do
        it 'shows no environments' do
          visit_environments(project, scope: 'stopped')

          expect(page).to have_content(s_('Environments|Get started with environments'))
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
          visit_environments(project, scope: 'active')

          expect(page).to have_link(environment.name, href: project_environment_path(project, environment))
        end
      end
    end

    describe 'with one stopped environment' do
      let!(:environment) { create(:environment, project: project, state: :stopped) }

      describe 'in active tab page' do
        it 'shows no environments' do
          visit_environments(project, scope: 'active')

          expect(page).to have_content(s_('Environments|Get started with environments'))
        end
      end

      describe 'in stopped tab page' do
        it 'shows one environment' do
          visit_environments(project, scope: 'stopped')

          expect(page).to have_link(environment.name, href: project_environment_path(project, environment))
          expect(page.all('[data-testid="stop-icon"]').length).to eq(0)
        end
      end
    end
  end

  context 'without environments' do
    before do
      visit_environments(project)
    end

    it 'does not show environments and tabs' do
      expect(page).to have_content(s_('Environments|Get started with environments'))

      expect(page).not_to have_link(_('Active'))
      expect(page).not_to have_link(_('Stopped'))
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
        expect(page).to have_link(environment.name, href: project_environment_path(project, environment))

        expect(page).to have_link("#{_('Active')} 1")
        expect(page).to have_link("#{_('Stopped')} 0")
      end

      it 'does not show deployments' do
        expect(page).to have_content(s_('Environments|There are no deployments for this environment yet. Learn more about setting up deployments.'))
      end

      it 'shows stop button when environment is not stoppable' do
        expect(page).to have_button('Stop')
      end
    end

    context 'when there are successful deployments' do
      let(:project) { create(:project, :repository) }

      let!(:deployment) do
        create(:deployment, :success, environment: environment, sha: project.commit.id)
      end

      it 'shows deployment SHA' do
        visit_environments(project)

        expect(page).to have_text(deployment.short_sha)
        expect(page).to have_link(deployment.commit.full_title)
      end

      context 'when builds and manual actions are present' do
        let!(:pipeline) { create(:ci_pipeline, project: project) }
        let!(:build) { create(:ci_build, :success, pipeline: pipeline) }

        let!(:action) do
          create(:ci_build, :manual, pipeline: pipeline, name: 'deploy to production')
        end

        let!(:deployment) do
          create(:deployment, :success, environment: environment, deployable: build, sha: project.commit.id)
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

        it 'shows a stop button and dialog' do
          expect(page).to have_selector(stop_button_selector)

          click_button(_('Stop'))

          within('.modal-body') do
            expect(page).to have_css('.warning_message')
          end
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
            create(:deployment, :success, environment: environment, deployable: build, on_stop: 'close_app')
          end

          it 'shows a stop button and dialog' do
            expect(page).to have_selector(stop_button_selector)

            click_button(_('Stop'))

            within('.modal-body') do
              expect(page).not_to have_css('.warning_message')
            end
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
                click_button(_('More actions'))
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
          create(:ci_build, :scheduled, pipeline: pipeline, name: 'delayed job', stage: 'test')
        end

        let!(:deployment) do
          create(:deployment, :success, environment: environment, deployable: build, sha: project.commit.id)
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
            create(:ci_build, :expired_scheduled, pipeline: pipeline, name: 'delayed job', stage: 'test')
          end

          it "shows 00:00:00 as the remaining time" do
            find(actions_button_selector).click

            expect(page).to have_content("00:00:00")
          end
        end

        context 'when user played a delayed job immediately' do
          before do
            find(actions_button_selector).click
            accept_gl_confirm do
              find(action_link_selector).click
            end

            # Wait for UI to transition to ensure we an GraphQL request has been made
            within(actions_button_selector) { find('.gl-spinner') }
            within(actions_button_selector) { find_by_testid('play-icon') }

            wait_for_requests
          end

          it 'enqueues the delayed job', :js, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/409990' do
            expect(delayed_job.reload).to be_pending
          end
        end
      end
    end

    context 'when there is a failed deployment' do
      let(:project) { create(:project, :repository) }

      let!(:deployment) do
        create(:deployment, :failed, environment: environment, sha: project.commit.id)
      end

      it 'does not show deployments', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/409990' do
        visit_environments(project)

        expect(page).to have_content(s_('Environments|There are no deployments for this environment yet. Learn more about setting up deployments.'))
      end
    end

    context 'when there is an upcoming deployment' do
      let_it_be(:project) { create(:project, :repository) }

      let!(:deployment) do
        create(:deployment, :running, environment: environment, sha: project.commit.id)
      end

      it "renders the upcoming deployment", :aggregate_failures do
        visit_environments(project)

        within(upcoming_deployment_content_selector) do
          expect(page).to have_content(project.commit.short_id)
          expect(page).to have_link(href: /#{deployment.user.username}/)
        end
      end
    end

    describe 'stop actions' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:project) { create(:project, :repository) }

      let(:warning_message) { 'no “stop environment action” being defined' }

      where(:status, :warning_present_if_ff_disabled) do
        :success  | false
        :failed   | true
        :canceled | true
      end

      with_them do
        before do
          pipeline = create(:ci_pipeline, status, project: project)
          build = create(:ci_build, status, pipeline: pipeline)
          create(:ci_build, :manual, project: project, pipeline: pipeline, name: 'stop_action')
          create(:deployment, status, environment: environment, deployable: build, sha: project.commit.id, on_stop: 'stop_action')

          visit_environments(project)
        end

        it 'shows a stop action dialog without a warning message' do
          click_button(_('Stop'))

          within('.modal-body') do
            expect(page).not_to have_content(warning_message)
          end
        end
      end
    end
  end

  it 'does have a new environment button' do
    visit_environments(project)

    expect(page).to have_link('Create an environment')
  end

  describe 'creating a new environment' do
    before do
      visit_environments(project)
    end

    context 'user is a developer' do
      let(:role) { :developer }

      it 'developer creates a new environment with a valid name' do
        click_link 'Create an environment'
        fill_in('Name', with: 'production')
        click_on 'Save'

        expect(page).to have_content('production')
      end

      it 'developer creates a new environment with invalid name' do
        click_link 'Create an environment'
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
        create(:environment, :will_auto_stop, project: project, name: 'staging/review-1', state: :available)
        create(:environment, :will_auto_stop, project: project, name: 'staging/review-2', state: :available)
      end

      it 'shows folder name linked to the folder page' do
        visit_environments(project)
        wait_for_requests

        expect(page).not_to have_content 'review-1'
        expect(page).not_to have_content 'review-2'
        expect(page).to have_content 'staging 2'

        expect(page).to have_link('staging')

        click_link 'staging'

        expect(page).to have_current_path(folder_project_environments_path(project, 'staging'))
        expect(page).to have_content 'Environments / staging'
      end
    end

    describe 'stopped environments' do
      before do
        create(:environment, :will_auto_stop, project: project, name: 'staging/review-1', state: :stopped)
        create(:environment, :will_auto_stop, project: project, name: 'staging/review-2', state: :stopped)
      end

      it 'shows folder name linked to the folder page' do
        visit_environments(project, scope: 'stopped')
        wait_for_requests

        expect(page).not_to have_content 'review-1'
        expect(page).not_to have_content 'review-2'
        expect(page).to have_content 'staging 2'

        expect(page).to have_link('staging')

        click_link 'staging'

        expect(page).to have_current_path(folder_project_environments_path(project, 'staging'))
        expect(page).to have_content 'Environments / staging'
      end
    end
  end

  def have_terminal_button
    have_link(_('Terminal'), href: terminal_project_environment_path(project, environment))
  end

  def visit_environments(project, **opts)
    visit project_environments_path(project, **opts)
    wait_for_requests
  end
end
