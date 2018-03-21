require 'spec_helper'

feature 'Environment' do
  given(:project) { create(:project) }
  given(:user) { create(:user) }
  given(:role) { :developer }

  background do
    sign_in(user)
    project.add_role(user, role)
  end

  feature 'environment details page' do
    given!(:environment) { create(:environment, project: project) }
    given!(:permissions) { }
    given!(:deployment) { }
    given!(:action) { }

    before do
      visit_environment(environment)
    end

    scenario 'shows environment name' do
      expect(page).to have_content(environment.name)
    end

    context 'without deployments' do
      scenario 'does show no deployments' do
        expect(page).to have_content('You don\'t have any deployments right now.')
      end
    end

    context 'with deployments' do
      context 'when there is no related deployable' do
        given(:deployment) do
          create(:deployment, environment: environment, deployable: nil)
        end

        scenario 'does show deployment SHA' do
          expect(page).to have_link(deployment.short_sha)
          expect(page).not_to have_link('Re-deploy')
          expect(page).not_to have_terminal_button
        end
      end

      context 'with related deployable present' do
        given(:pipeline) { create(:ci_pipeline, project: project) }
        given(:build) { create(:ci_build, pipeline: pipeline) }

        given(:deployment) do
          create(:deployment, environment: environment, deployable: build)
        end

        scenario 'does show build name' do
          expect(page).to have_link("#{build.name} (##{build.id})")
          expect(page).to have_link('Re-deploy')
          expect(page).not_to have_terminal_button
        end

        context 'with manual action' do
          given(:action) do
            create(:ci_build, :manual, pipeline: pipeline,
                                       name: 'deploy to production')
          end

          context 'when user has ability to trigger deployment' do
            given(:permissions) do
              create(:protected_branch, :developers_can_merge,
                     name: action.ref, project: project)
            end

            it 'does show a play button' do
              expect(page).to have_link(action.name.humanize)
            end

            it 'does allow to play manual action' do
              expect(action).to be_manual

              expect { click_link(action.name.humanize) }
                .not_to change { Ci::Pipeline.count }

              expect(page).to have_content(action.name)
              expect(action.reload).to be_pending
            end
          end

          context 'when user has no ability to trigger a deployment' do
            it 'does not show a play button' do
              expect(page).not_to have_link(action.name.humanize)
            end
          end

          context 'with external_url' do
            given(:environment) { create(:environment, project: project, external_url: 'https://git.gitlab.com') }
            given(:build) { create(:ci_build, pipeline: pipeline) }
            given(:deployment) { create(:deployment, environment: environment, deployable: build) }

            scenario 'does show an external link button' do
              expect(page).to have_link(nil, href: environment.external_url)
            end
          end

          context 'with terminal' do
            shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
              context 'for project master' do
                let(:role) { :master }

                scenario 'it shows the terminal button' do
                  expect(page).to have_terminal_button
                end

                context 'web terminal', :js do
                  before do
                    # Stub #terminals as it causes js-enabled feature specs to render the page incorrectly
                    allow_any_instance_of(Environment).to receive(:terminals) { nil }
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

                scenario 'does not show terminal button' do
                  expect(page).not_to have_terminal_button
                end
              end
            end

            context 'when user configured kubernetes from Integration > Kubernetes' do
              let(:project) { create(:kubernetes_project, :test_repo) }

              it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
            end

            context 'when user configured kubernetes from CI/CD > Clusters' do
              let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
              let(:project) { cluster.project }

              it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
            end
          end

          context 'when environment is available' do
            context 'with stop action' do
              given(:action) do
                create(:ci_build, :manual, pipeline: pipeline,
                                           name: 'close_app')
              end

              given(:deployment) do
                create(:deployment, environment: environment,
                                    deployable: build,
                                    on_stop: 'close_app')
              end

              context 'when user has ability to stop environment' do
                given(:permissions) do
                  create(:protected_branch, :developers_can_merge,
                         name: action.ref, project: project)
                end

                it 'allows to stop environment' do
                  click_link('Stop')

                  expect(page).to have_content('close_app')
                end
              end

              context 'when user has no ability to stop environment' do
                it 'does not allow to stop environment' do
                  expect(page).to have_no_link('Stop')
                end
              end

              context 'for reporter' do
                let(:role) { :reporter }

                scenario 'does not show stop button' do
                  expect(page).not_to have_link('Stop')
                end
              end
            end
          end

          context 'when environment is stopped' do
            given(:environment) { create(:environment, project: project, state: :stopped) }

            scenario 'does not show stop button' do
              expect(page).not_to have_link('Stop')
            end
          end
        end
      end
    end
  end

  feature 'environment folders', :js do
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

  feature 'auto-close environment when branch is deleted' do
    given(:project) { create(:project, :repository) }

    given!(:environment) do
      create(:environment, :with_review_app, project: project,
                                             ref: 'feature')
    end

    scenario 'user visits environment page' do
      visit_environment(environment)

      expect(page).to have_link('Stop')
    end

    scenario 'user deletes the branch with running environment' do
      visit project_branches_filtered_path(project, state: 'all', search: 'feature')

      remove_branch_with_hooks(project, user, 'feature') do
        page.within('.js-branch-feature') { find('a.btn-remove').click }
      end

      visit_environment(environment)

      expect(page).to have_no_link('Stop')
    end

    ##
    # This is a workaround for problem described in #24543
    #
    def remove_branch_with_hooks(project, user, branch)
      params = {
        oldrev: project.commit(branch).id,
        newrev: Gitlab::Git::BLANK_SHA,
        ref: "refs/heads/#{branch}"
      }

      yield

      GitPushService.new(project, user, params).execute
    end
  end

  def visit_environment(environment)
    visit project_environment_path(environment.project, environment)
  end

  def have_terminal_button
    have_link(nil, href: terminal_project_environment_path(project, environment))
  end
end
