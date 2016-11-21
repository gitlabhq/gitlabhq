require 'spec_helper'

feature 'Environment', :feature do
  given(:project) { create(:empty_project) }
  given(:user) { create(:user) }
  given(:role) { :developer }

  background do
    login_as(user)
    project.team << [user, role]
  end

  feature 'environment details page' do
    given!(:environment) { create(:environment, project: project) }
    given!(:deployment) { }
    given!(:manual) { }

    before do
      visit_environment(environment)
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
        end

        scenario 'does not show a re-deploy button for deployment without build' do
          expect(page).not_to have_link('Re-deploy')
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
        end

        scenario 'does show re-deploy button' do
          expect(page).to have_link('Re-deploy')
        end

        scenario 'does not show stop button' do
          expect(page).not_to have_link('Stop')
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

  feature 'auto-close environment when branch is deleted' do
    given(:project) { create(:project) }

    given!(:environment) do
      create(:environment, :with_review_app, project: project,
                                             ref: 'feature')
    end

    scenario 'user visits environment page' do
      visit_environment(environment)

      expect(page).to have_link('Stop')
    end

    scenario 'user deletes the branch with running environment' do
      visit namespace_project_branches_path(project.namespace, project)

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
    visit namespace_project_environment_path(environment.project.namespace,
                                             environment.project,
                                             environment)
  end
end
