# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Group manages runners in runner list", :freeze_time, :js, feature_category: :fleet_visibility do
  include Spec::Support::Helpers::ModalHelpers
  include Features::RunnersHelpers

  let_it_be(:group_owner) { create(:user) }
  let_it_be(:group) { create(:group, owners: group_owner) }
  let_it_be(:project) { create(:project, group: group) }

  before_all do
    freeze_time # Freeze time before `let_it_be` runs, so that runner statuses are frozen during execution
  end

  after :all do
    unfreeze_time
  end

  before do
    sign_in(group_owner)

    visit group_runners_path(group)
  end

  context "with an online group runner" do
    let_it_be(:group_runner) { create(:ci_runner, :group, :almost_offline, groups: [group]) }

    it_behaves_like 'pauses, resumes and deletes a runner' do
      let(:runner) { group_runner }
    end

    it 'shows an edit link' do
      within_runner_row(group_runner.id) do
        expect(find_link('Edit')[:href]).to end_with(edit_group_runner_path(group, group_runner))
      end
    end
  end

  context "with an online project runner" do
    let_it_be(:project_runner) do
      create(:ci_runner, :project, :almost_offline, projects: [project])
    end

    it_behaves_like 'pauses, resumes and deletes a runner' do
      let(:runner) { project_runner }
    end

    it 'shows an editable project runner' do
      within_runner_row(project_runner.id) do
        expect(find_link('Edit')[:href]).to end_with(edit_group_runner_path(group, project_runner))
      end
    end
  end

  context 'with a multi-project runner' do
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:project_2) { create(:project, group: group) }
    let_it_be(:runner) do
      create(:ci_runner, :project, projects: [project, project_2], description: 'group-runner')
    end

    it 'owner cannot remove the project runner' do
      within_runner_row(runner.id) do
        expect(page).not_to have_button 'Delete runner'
      end
    end
  end

  context "with multiple runners" do
    before do
      create_list(:ci_runner, 2, :group, groups: [group])

      visit group_runners_path(group)
    end

    it_behaves_like 'deletes runners in bulk' do
      let(:runner_count) { '2' }
    end
  end
end
