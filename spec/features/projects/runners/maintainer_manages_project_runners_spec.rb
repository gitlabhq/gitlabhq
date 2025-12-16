# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Maintainer manages project runners', feature_category: :fleet_visibility do
  include Features::RunnersHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }

  before do
    sign_in(user)
  end

  context "with a project runner", :js do
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

    before do
      visit project_runners_path(project)
    end

    it_behaves_like 'shows runner summary and navigates to details' do
      let(:runner) { project_runner }
      let(:runner_page_path) { project_runner_path(project, project_runner) }
    end

    it_behaves_like 'pauses, resumes and deletes a runner' do
      let(:runner) { project_runner }
    end

    it 'shows an instance badge' do
      within_runner_row(project_runner.id) do
        expect(page).to have_selector '.badge', text: 'Project'
      end
    end
  end

  context 'with a project runner from another project', :js do
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_2_runner) { create(:ci_runner, :project, projects: [project_2]) }

    before_all do
      project_2.add_maintainer(user)
    end

    before do
      visit project_runners_path(project)
    end

    it 'assigns the runner' do
      click_on 'Other available project runners'

      within_runner_row(project_2_runner.id) do
        click_on 'Assign to project'
      end

      expect(page.find('.gl-toast')).to have_text(/Runner .+ was assigned to this project/)

      wait_for_requests

      expect(page).not_to have_content(project_2_runner.short_sha)

      # Find runner in the "Assigned project runners" tab
      click_on 'Assigned project runners'

      within_runner_row(project_2_runner.id) do
        expect(page).to have_content(project_2_runner.short_sha)
        expect(page).to have_button('Unassign from project')
      end
    end
  end

  context 'when updating a runner' do
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

    before do
      visit edit_project_runner_path(project, project_runner)
    end

    it_behaves_like 'submits edit runner form' do
      let(:runner) { project_runner }
      let(:runner_page_path) { project_runner_path(project, project_runner) }
    end
  end
end
