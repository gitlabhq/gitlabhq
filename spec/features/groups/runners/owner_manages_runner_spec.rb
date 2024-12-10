# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Group owner manages runners", :freeze_time, :js, feature_category: :fleet_visibility do
  let_it_be(:group_owner) { create(:user) }
  let_it_be(:group) { create(:group, owners: group_owner) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    sign_in(group_owner)
  end

  describe "shows runner details" do
    let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group], description: 'runner-foo') }
    let_it_be(:group_runner_job) { create(:ci_build, runner: group_runner, project: project) }

    before do
      visit group_runner_path(group, group_runner)
    end

    it 'shows runner details' do
      expect(page).to have_content 'Description runner-foo'
    end

    it_behaves_like 'shows runner jobs tab' do
      let(:job_count) { '1' }
      let(:job) { group_runner_job }
    end
  end

  describe "edits runner" do
    before do
      visit edit_group_runner_path(group, runner)
    end

    context 'when updating a group runner' do
      let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }

      it_behaves_like 'submits edit runner form' do
        let(:runner_page_path) { group_runner_path(group, runner) }
      end
    end

    context 'when updating a project runner' do
      let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }

      it_behaves_like 'submits edit runner form' do
        let(:runner_page_path) { group_runner_path(group, runner) }
      end

      it_behaves_like 'shows locked field'
    end
  end
end
