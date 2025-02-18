# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin manages runner in admin section", :js, feature_category: :fleet_visibility do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  describe 'shows runner' do
    let_it_be(:runner) { create(:ci_runner, description: 'runner-foo', tag_list: ['tag1']) }
    let_it_be(:runner_job) { create(:ci_build, runner: runner) }

    before do
      visit admin_runner_path(runner)
    end

    describe 'runner show page breadcrumbs' do
      it 'contains the current runner id and token' do
        within_testid('breadcrumb-links') do
          expect(find('li:last-of-type')).to have_link("##{runner.id} (#{runner.short_sha})")
        end
      end
    end

    it 'shows runner details' do
      aggregate_failures do
        expect(page).to have_content 'Description runner-foo'
        expect(page).to have_content 'Last contact Never contacted'
        expect(page).to have_content 'Configuration Runs untagged jobs'
        expect(page).to have_content 'Maximum job timeout None'
        expect(page).to have_content 'Tags tag1'
      end
    end

    it_behaves_like 'shows runner jobs tab' do
      let(:job_count) { '1' }
      let(:job) { runner_job }
    end

    describe 'when a runner is deleted' do
      before do
        click_on 'Delete runner'

        within_modal do
          click_on 'Permanently delete runner'
        end
      end

      it 'deletes runner and redirects to runner list' do
        expect(find_by_testid('alert-success')).to have_content('deleted')
        expect(current_url).to match(admin_runners_path)
      end
    end
  end

  describe "edits runner" do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project, organization: project1.organization) }
    let_it_be(:project_runner) { create(:ci_runner, :project, :unregistered, projects: [create(:project)]) }

    before do
      visit edit_admin_runner_path(project_runner)
    end

    it_behaves_like 'submits edit runner form' do
      let(:runner) { project_runner }
      let(:runner_page_path) { admin_runner_path(project_runner) }
    end

    it_behaves_like 'shows locked field'

    describe 'breadcrumbs' do
      it 'contains the current runner id and token' do
        within_testid('breadcrumb-links') do
          expect(page).to have_link("##{project_runner.id} (#{project_runner.short_sha})")
          expect(find('li:last-of-type')).to have_content("Edit")
        end
      end
    end

    describe 'runner header' do
      it 'contains the runner status, type and id' do
        expect(page).to have_content(
          "##{project_runner.id} (#{project_runner.short_sha}) #{s_('Runners|Never contacted')} Project Created"
        )
      end
    end

    context 'when a runner is updated' do
      before do
        click_on _('Save changes')
      end

      it 'show success alert and redirects to runner page' do
        expect(current_url).to match(admin_runner_path(project_runner))
        expect(find_by_testid('alert-success')).to have_content('saved')
      end
    end

    describe 'projects' do
      it 'contains project names' do
        expect(page).to have_content(project1.full_name)
        expect(page).to have_content(project2.full_name)
      end
    end

    describe 'search' do
      before do
        search_form = find('#runner-projects-search')
        search_form.fill_in 'search', with: project1.name
        search_form.click_button 'Search'
      end

      it 'contains name of correct project' do
        expect(page).to have_content(project1.full_name)
        expect(page).not_to have_content(project2.full_name)
      end
    end

    describe 'enable/create' do
      shared_examples 'assignable runner' do
        it 'enables a runner for a project' do
          within_testid('unassigned-projects') do
            within('tr', text: project2.full_name) do
              click_on 'Enable'
            end
          end

          assigned_project = find_by_testid('assigned-projects')

          expect(page).to have_content('Runner assigned to project.')
          expect(assigned_project).to have_content(project2.name)
        end
      end

      context 'with project runner' do
        let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project1]) }

        before do
          visit edit_admin_runner_path(project_runner)
        end

        it_behaves_like 'assignable runner'
      end

      context 'with locked runner' do
        let_it_be(:locked_runner) { create(:ci_runner, :project, projects: [project1], locked: true) }

        before do
          visit edit_admin_runner_path(locked_runner)
        end

        it_behaves_like 'assignable runner'
      end
    end

    describe 'disable/destroy' do
      context 'when runner is being removed from owner project' do
        it 'denies removing project runner from project' do
          within_testid('assigned-projects') do
            click_on 'Disable'
          end

          new_runner_project = find_by_testid('unassigned-projects')

          expect(page).to have_content('Failed unassigning runner from project')
          expect(new_runner_project).to have_content(project2.name)
        end
      end

      context 'when project being disabled is runner owner project' do
        let_it_be(:runner) { create(:ci_runner, :project, projects: [project1, project2]) }

        let(:project_to_delete) { project2 }
        let(:runner_project_to_delete) { runner.runner_projects.find_by_project_id(project_to_delete.id) }
        let(:delete_route_path) do
          admin_namespace_project_runner_project_path(
            id: runner_project_to_delete,
            project_id: project_to_delete,
            namespace_id: project_to_delete.parent
          )
        end

        before do
          visit edit_admin_runner_path(runner)
        end

        it 'removes project runner from project' do
          within_testid('assigned-projects') do
            find("a[href='#{delete_route_path}']").click
          end

          new_runner_project = find_by_testid('unassigned-projects')

          expect(page).to have_content('Runner unassigned from project.')
          expect(new_runner_project).to have_content(project_to_delete.name)
        end
      end
    end
  end
end
