require 'spec_helper'

feature 'Groups > Pipeline Quota', feature: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:project) { create(:empty_project, namespace: group, shared_runners_enabled: true) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with no quota' do
    let(:group) { create(:group, :with_build_minutes) }

    it 'is not linked within the group settings dropdown' do
      visit group_path(group)

      page.within('.layout-nav') do
        expect(page).not_to have_selector(:link_or_button, 'Pipeline Quota')
      end
    end

    it 'shows correct group quota info' do
      visit_pipeline_quota_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("400 / Unlimited minutes")
        expect(page).to have_selector('.progress-bar-success')
      end
    end
  end

  context 'with no projects using shared runners' do
    let(:group) { create(:group, :with_not_used_build_minutes_limit) }
    let!(:project) { create(:empty_project, namespace: group, shared_runners_enabled: false) }

    it 'is not linked within the group settings dropdown' do
      visit edit_group_path(group)

      expect(page).not_to have_link('Pipelines quota')
    end

    it 'shows correct group quota info' do
      visit_pipeline_quota_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("300 / Unlimited minutes")
        expect(page).to have_selector('.progress-bar-success')
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
        expect(page).to have_selector('.progress-bar-success')
      end
    end
  end

  context 'minutes over quota' do
    let(:group) { create(:group, :with_used_build_minutes_limit) }
    let!(:other_project) { create(:empty_project, namespace: group, shared_runners_enabled: false) }

    it 'is linked within the group settings tab' do
      visit edit_group_path(group)

      expect(page).to have_link('Pipelines quota')
    end

    it 'shows correct group quota and projects info' do
      visit_pipeline_quota_page

      page.within('.pipeline-quota') do
        expect(page).to have_content("1000 / 500 minutes")
        expect(page).to have_content("200% used")
        expect(page).to have_selector('.progress-bar-danger')
      end

      page.within('.pipeline-project-metrics') do
        expect(page).to have_content(project.name)
        expect(page).not_to have_content(other_project.name)
      end
    end
  end

  def visit_pipeline_quota_page
    visit group_pipeline_quota_path(group)
  end
end
