# frozen_string_literal: true

require 'spec_helper'

describe 'Environment' do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:role) { :developer }

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  def auto_stop_button_selector
    %q{button[title="Prevent environment from auto-stopping"]}
  end

  describe 'environment details page' do
    let!(:environment) { create(:environment, project: project) }
    let!(:permissions) { }
    let!(:deployment) { }
    let!(:action) { }
    let!(:cluster) { }

    before do
      visit_environment(environment)
    end

    it 'shows environment name' do
      expect(page).to have_content(environment.name)
    end

    context 'without auto-stop' do
      it 'does not show auto-stop text' do
        expect(page).not_to have_content('Auto stops')
      end

      it 'does not show auto-stop button' do
        expect(page).not_to have_selector(auto_stop_button_selector)
      end
    end

    context 'with auto-stop' do
      let!(:environment) { create(:environment, :will_auto_stop, name: 'staging', project: project) }

      before do
        visit_environment(environment)
      end

      it 'shows auto stop info' do
        expect(page).to have_content('Auto stops')
      end

      it 'shows auto stop button' do
        expect(page).to have_selector(auto_stop_button_selector)
        expect(page.find(auto_stop_button_selector).find(:xpath, '..')['action']).to have_content(cancel_auto_stop_project_environment_path(environment.project, environment))
      end

      it 'allows user to cancel auto stop', :js do
        page.find(auto_stop_button_selector).click
        wait_for_all_requests
        expect(page).to have_content('Auto stop successfully canceled.')
        expect(page).not_to have_selector(auto_stop_button_selector)
      end
    end

    context 'without deployments' do
      it 'does not show deployments' do
        expect(page).to have_content('You don\'t have any deployments right now.')
      end
    end

    context 'with deployments' do
      context 'when there is no related deployable' do
        let(:deployment) do
          create(:deployment, :success, environment: environment, deployable: nil)
        end

        it 'does show deployment SHA' do
          expect(page).to have_link(deployment.short_sha)
          expect(page).not_to have_link('Re-deploy')
          expect(page).not_to have_terminal_button
        end
      end

      context 'when there is a successful deployment' do
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:build) { create(:ci_build, :success, pipeline: pipeline) }

        let(:deployment) do
          create(:deployment, :success, environment: environment, deployable: build)
        end

        it 'does show deployments' do
          expect(page).to have_link("#{build.name} (##{build.id})")
        end
      end

      context 'when there is a running deployment' do
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:build) { create(:ci_build, pipeline: pipeline) }

        let(:deployment) do
          create(:deployment, :running, environment: environment, deployable: build)
        end

        it 'does show deployments' do
          expect(page).to have_link("#{build.name} (##{build.id})")
        end
      end

      context 'when there is a failed deployment' do
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:build) { create(:ci_build, pipeline: pipeline) }

        let(:deployment) do
          create(:deployment, :failed, environment: environment, deployable: build)
        end

        it 'does show deployments' do
          expect(page).to have_link("#{build.name} (##{build.id})")
        end
      end

      context 'with related deployable present' do
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:build) { create(:ci_build, pipeline: pipeline) }

        let(:deployment) do
          create(:deployment, :success, environment: environment, deployable: build)
        end

        it 'does show build name' do
          expect(page).to have_link("#{build.name} (##{build.id})")
        end

        it 'shows the re-deploy button' do
          expect(page).to have_button('Re-deploy to environment')
        end

        context 'with manual action' do
          let(:action) do
            create(:ci_build, :manual, pipeline: pipeline,
                                       name: 'deploy to production', environment: environment.name)
          end

          context 'when user has ability to trigger deployment' do
            let(:permissions) do
              create(:protected_branch, :developers_can_merge,
                     name: action.ref, project: project)
            end

            it 'does show a play button' do
              expect(page).to have_link(action.name)
            end

            it 'does allow to play manual action', :js do
              expect(action).to be_manual

              find('button.dropdown').click

              expect { click_link(action.name) }
                .not_to change { Ci::Pipeline.count }

              wait_for_all_requests

              expect(page).to have_content(action.name)
              expect(action.reload).to be_pending
            end
          end

          context 'when user has no ability to trigger a deployment' do
            let(:permissions) do
              create(:protected_branch, :no_one_can_merge,
                     name: action.ref, project: project)
            end

            it 'does not show a play button' do
              expect(page).not_to have_link(action.name)
            end
          end

          context 'with external_url' do
            let(:environment) { create(:environment, project: project, external_url: 'https://git.gitlab.com') }
            let(:build) { create(:ci_build, pipeline: pipeline) }
            let(:deployment) { create(:deployment, :success, environment: environment, deployable: build) }

            it 'does show an external link button' do
              expect(page).to have_link(nil, href: environment.external_url)
            end
          end

          context 'with terminal' do
            context 'when user configured kubernetes from CI/CD > Clusters' do
              let!(:cluster) do
                create(:cluster, :project, :provided_by_gcp, projects: [project])
              end

              context 'for project maintainer' do
                let(:role) { :maintainer }

                it 'shows the terminal button' do
                  expect(page).to have_terminal_button
                end

                context 'web terminal', :js do
                  before do
                    # Stub #terminals as it causes js-enabled feature specs to
                    # render the page incorrectly
                    #
                    # In EE we have to stub EE::Environment since it overwrites
                    # the "terminals" method.
                    allow_next_instance_of(Gitlab.ee? ? EE::Environment : Environment) do |instance|
                      allow(instance).to receive(:terminals) { nil }
                    end

                    visit terminal_project_environment_path(project, environment)
                  end

                  it 'displays a web terminal' do
                    expect(page).to have_selector('#terminal')
                    expect(page).to have_link(nil, href: environment.external_url)
                  end
                end
              end

              context 'for developer' do
                let(:role) { :developer }

                it 'does not show terminal button' do
                  expect(page).not_to have_terminal_button
                end
              end
            end
          end

          context 'when environment is available' do
            context 'with stop action' do
              let(:action) do
                create(:ci_build, :manual, pipeline: pipeline,
                                           name: 'close_app')
              end

              let(:deployment) do
                create(:deployment, :success,
                                    environment: environment,
                                    deployable: build,
                                    on_stop: 'close_app')
              end

              context 'when user has ability to stop environment' do
                let(:permissions) do
                  create(:protected_branch, :developers_can_merge,
                         name: action.ref, project: project)
                end

                it 'allows to stop environment', :js do
                  click_button('Stop')
                  click_button('Stop environment') # confirm modal
                  wait_for_all_requests
                  expect(page).to have_content('close_app')
                end
              end

              context 'when user has no ability to stop environment' do
                let(:permissions) do
                  create(:protected_branch, :no_one_can_merge,
                         name: action.ref, project: project)
                end

                it 'does not allow to stop environment' do
                  expect(page).not_to have_button('Stop')
                end
              end

              context 'for reporter' do
                let(:role) { :reporter }

                it 'does not show stop button' do
                  expect(page).not_to have_button('Stop')
                end
              end
            end
          end

          context 'when environment is stopped' do
            let(:environment) { create(:environment, project: project, state: :stopped) }

            it 'does not show stop button' do
              expect(page).not_to have_button('Stop')
            end
          end
        end
      end
    end
  end

  describe 'environment folders', :js do
    context 'when folder name contains special charaters' do
      before do
        create(:environment, project: project,
                             name: 'staging-1.0/review',
                             state: :available)
      end

      it 'renders a correct environment folder' do
        reqs = inspect_requests do
          visit folder_project_environments_path(project, id: 'staging-1.0')
        end

        expect(reqs.first.status_code).to eq(200)
        expect(page).to have_content('Environments / staging-1.0')
      end
    end
  end

  describe 'auto-close environment when branch is deleted' do
    let(:project) { create(:project, :repository) }

    let!(:environment) do
      create(:environment, :with_review_app, project: project,
                                             ref: 'feature')
    end

    it 'user visits environment page' do
      visit_environment(environment)

      expect(page).to have_button('Stop')
    end

    it 'user deletes the branch with running environment' do
      visit project_branches_filtered_path(project, state: 'all', search: 'feature')

      remove_branch_with_hooks(project, user, 'feature') do
        page.within('.js-branch-feature') { find('a.btn-remove').click }
      end

      visit_environment(environment)

      expect(page).not_to have_button('Stop')
    end

    ##
    # This is a workaround for problem described in #24543
    #
    def remove_branch_with_hooks(project, user, branch)
      params = {
        change: {
          oldrev: project.commit(branch).id,
          newrev: Gitlab::Git::BLANK_SHA,
          ref: "refs/heads/#{branch}"
        }
      }

      yield

      Git::BranchPushService.new(project, user, params).execute
    end
  end

  def visit_environment(environment)
    visit project_environment_path(environment.project, environment)
  end

  def have_terminal_button
    have_link(nil, href: terminal_project_environment_path(project, environment))
  end
end
