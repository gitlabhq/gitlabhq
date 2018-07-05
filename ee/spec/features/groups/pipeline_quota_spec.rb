require 'spec_helper'

describe 'Groups > Pipeline Quota' do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:project) { create(:project, namespace: group, shared_runners_enabled: true) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with no quota' do
    let(:group) { create(:group, :with_build_minutes) }

    it 'is not linked within the group settings dropdown' do
      visit group_path(group)

      page.within('.nav-sidebar') do
        expect(page).not_to have_selector(:link_or_button, 'Pipeline Quota')
      end
    end

    it 'shows correct group quota info' do
      visit_pipeline_quota_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("400 / Unlimited minutes")
        expect(page).to have_selector('.bg-success')
      end
    end
  end

  context 'with no projects using shared runners' do
    let(:group) { create(:group, :with_not_used_build_minutes_limit) }
    let!(:project) { create(:project, namespace: group, shared_runners_enabled: false) }

    it 'is not linked within the group settings dropdown' do
      visit edit_group_path(group)

      expect(page).not_to have_link('Pipelines quota')
    end

    it 'shows correct group quota info' do
      visit_pipeline_quota_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("300 / Unlimited minutes")
        expect(page).to have_selector('.bg-success')
      end

      page.within('.pipeline-project-metrics') do
        expect(page).to have_content('This group has no projects which use shared runners')
      end
    end
  end

  context 'minutes under quota' do
    let(:group) { create(:group, :with_not_used_build_minutes_limit) }

    it 'is linked within the group settings tab' do
      visit edit_group_path(group)

      expect(page).to have_link('Pipelines quota')
    end

    it 'shows correct group quota info' do
      visit_pipeline_quota_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("300 / 500 minutes")
        expect(page).to have_content("60% used")
        expect(page).to have_selector('.bg-success')
      end
    end
  end

  context 'minutes over quota' do
    let(:group) { create(:group, :with_used_build_minutes_limit) }
    let!(:other_project) { create(:project, namespace: group, shared_runners_enabled: false) }

    it 'is linked within the group settings tab' do
      visit edit_group_path(group)

      expect(page).to have_link('Pipelines quota')
    end

    it 'shows correct group quota and projects info' do
      visit_pipeline_quota_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("1000 / 500 minutes")
        expect(page).to have_content("200% used")
        expect(page).to have_selector('.bg-danger')
      end

      page.within('.pipeline-project-metrics') do
        expect(page).to have_content(project.full_name)
        expect(page).not_to have_content(other_project.full_name)
      end
    end
  end

  context 'with shared_runner_minutes_on_root_namespace disabled' do
    before do
      stub_feature_flags(shared_runner_minutes_on_root_namespace: false)
    end

    context 'when accessing group with subgroups' do
      let(:group) { create(:group, :with_used_build_minutes_limit) }
      let!(:subgroup) { create(:group, parent: group) }
      let!(:subproject) { create(:project, namespace: subgroup, shared_runners_enabled: true) }

      it 'does not show project of subgroup' do
        visit_pipeline_quota_page

        expect(page).to have_content(project.full_name)
        expect(page).not_to have_content(subproject.full_name)
      end
    end
  end

  context 'with shared_runner_minutes_on_root_namespace enabled', :nested_groups do
    before do
      stub_feature_flags(shared_runner_minutes_on_root_namespace: true)
    end

    context 'when accessing subgroup' do
      let(:root_ancestor) { create(:group) }
      let(:group) { create(:group, parent: root_ancestor) }

      it 'does not show subproject' do
        visit_pipeline_quota_page

        expect(page).to have_http_status(:not_found)
      end
    end

    context 'when accesing root group' do
      let!(:subgroup) { create(:group, parent: group) }
      let!(:subproject) { create(:project, namespace: subgroup, shared_runners_enabled: true) }

      it 'does show projects of subgroup' do
        visit_pipeline_quota_page

        expect(page).to have_content(project.full_name)
        expect(page).to have_content(subproject.full_name)
      end
    end
  end

  def visit_pipeline_quota_page
    visit group_pipeline_quota_path(group)
  end
end
